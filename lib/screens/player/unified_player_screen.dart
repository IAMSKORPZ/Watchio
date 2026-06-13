import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/content_type.dart';
import '../../models/playback_item.dart';
import '../../models/player_engine.dart';
import '../../models/playlist_content_model.dart';
import '../../repositories/user_preferences.dart';
import '../../services/player/app_player_controller.dart';
import '../../services/player/player_factory.dart';
import '../../services/watch_history_service.dart';
import '../../models/watch_history.dart';
import '../../services/app_state.dart';
import '../../shared/widgets/glass_panel.dart';

class UnifiedPlayerScreen extends StatefulWidget {
  final ContentItem contentItem;
  final List<ContentItem>? queue;

  const UnifiedPlayerScreen({
    super.key,
    required this.contentItem,
    this.queue,
  });

  @override
  State<UnifiedPlayerScreen> createState() => _UnifiedPlayerScreenState();
}

class _UnifiedPlayerScreenState extends State<UnifiedPlayerScreen> {
  late AppPlayerController _playerController;
  late PlaybackItem _currentPlaybackItem;
  bool _showControls = true;
  Timer? _controlsTimer;
  final WatchHistoryService _historyService = WatchHistoryService();
  
  @override
  void initState() {
    super.initState();
    _currentPlaybackItem = PlaybackItem.fromContentItem(widget.contentItem);
    _initPlayer();
    _startControlsTimer();
  }

  Future<void> _initPlayer() async {
    final engineStr = await UserPreferences.getPlayerEngine();
    final engine = PlayerEngine.values.firstWhere(
      (e) => e.name == engineStr, 
      orElse: () => PlayerEngine.auto
    );

    _playerController = PlayerFactory.create(engine);
    await _playerController.initialize();
    
    // Check watch history for VOD/Series
    Duration startPos = Duration.zero;
    if (_currentPlaybackItem.contentType != ContentType.liveStream) {
      final history = await _historyService.getWatchHistory(
        AppState.currentPlaylist!.id, 
        _currentPlaybackItem.id
      );
      if (history != null && history.watchDuration != null) {
        startPos = history.watchDuration!;
      }
    }

    final updatedItem = PlaybackItem(
      id: _currentPlaybackItem.id,
      url: _currentPlaybackItem.url,
      title: _currentPlaybackItem.title,
      imagePath: _currentPlaybackItem.imagePath,
      contentType: _currentPlaybackItem.contentType,
      startPosition: startPos,
      originalItem: _currentPlaybackItem.originalItem,
    );

    await _playerController.setDataSource(updatedItem);
    
    _playerController.addListener(_onPlayerStateChanged);
  }

  void _onPlayerStateChanged() {
    if (mounted) setState(() {});
    
    // Save history periodically for VOD
    if (_currentPlaybackItem.contentType != ContentType.liveStream && 
        _playerController.isPlaying && 
        _playerController.position.inSeconds % 10 == 0) {
      _saveHistory();
    }
  }

  Future<void> _saveHistory() async {
    await _historyService.saveWatchHistory(
      WatchHistory(
        playlistId: AppState.currentPlaylist!.id,
        contentType: _currentPlaybackItem.contentType,
        streamId: _currentPlaybackItem.id,
        lastWatched: DateTime.now(),
        title: _currentPlaybackItem.title,
        imagePath: _currentPlaybackItem.imagePath,
        totalDuration: _playerController.duration,
        watchDuration: _playerController.position,
      ),
    );
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _playerController.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) _startControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    if (_currentPlaybackItem.contentType != ContentType.liveStream) {
      _saveHistory();
    }
    _playerController.removeListener(_onPlayerStateChanged);
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): _ShowControlsIntent(),
          SingleActivator(LogicalKeyboardKey.arrowDown): _ShowControlsIntent(),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _SeekBackIntent(),
          SingleActivator(LogicalKeyboardKey.arrowRight): _SeekForwardIntent(),
        },
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              if (!_showControls) {
                _toggleControls();
              } else {
                _playerController.isPlaying ? _playerController.pause() : _playerController.play();
                _startControlsTimer();
              }
              return null;
            }),
            _ShowControlsIntent: CallbackAction<_ShowControlsIntent>(onInvoke: (_) {
              _toggleControls();
              return null;
            }),
            _SeekBackIntent: CallbackAction<_SeekBackIntent>(onInvoke: (_) {
              if (_currentPlaybackItem.contentType != ContentType.liveStream) {
                _playerController.seek(_playerController.position - const Duration(seconds: 10));
                if (!_showControls) _toggleControls();
              }
              return null;
            }),
            _SeekForwardIntent: CallbackAction<_SeekForwardIntent>(onInvoke: (_) {
              if (_currentPlaybackItem.contentType != ContentType.liveStream) {
                _playerController.seek(_playerController.position + const Duration(seconds: 30));
                if (!_showControls) _toggleControls();
              }
              return null;
            }),
          },
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (!_showControls && event is KeyDownEvent) {
                _toggleControls();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Stack(
              children: [
                // Video Layer
                Positioned.fill(child: _playerController.buildPlayerView(context)),

                // Buffering
                if (_playerController.isBuffering)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFC12CFF))),

                // Error State
                if (_playerController.error != null)
                  _buildErrorState(),

                // UI Overlay
                if (_showControls) _buildControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: GlassPanel(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              'Playback Error',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _playerController.error ?? 'Unknown error occurred',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _playerController.setDataSource(_currentPlaybackItem),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC12CFF)),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                if (_currentPlaybackItem.contentType != ContentType.liveStream)
                  _buildSeekBar(),
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentPlaybackItem.title,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_currentPlaybackItem.subtitle != null)
                Text(
                  _currentPlaybackItem.subtitle!,
                  style: const TextStyle(color: Color(0xFF00B7FF), fontSize: 14, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
        if (_currentPlaybackItem.isLive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildSeekBar() {
    final pos = _playerController.position;
    final dur = _playerController.duration;
    final progress = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFC12CFF),
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            trackHeight: 4,
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (v) {
              final target = Duration(milliseconds: (v * dur.inMilliseconds).toInt());
              _playerController.seek(target);
              _startControlsTimer();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(pos), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_formatDuration(dur), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            _playerController.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 48,
          ),
          onPressed: () {
            _playerController.isPlaying ? _playerController.pause() : _playerController.play();
            _startControlsTimer();
          },
        ),
        const SizedBox(width: 32),
        _ControlBtn(icon: Icons.subtitles_rounded, onTap: _showSubtitleMenu),
        const SizedBox(width: 16),
        _ControlBtn(icon: Icons.audiotrack_rounded, onTap: _showAudioMenu),
        const SizedBox(width: 16),
        _ControlBtn(icon: Icons.aspect_ratio_rounded, onTap: _showAspectRatioMenu),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  void _showSubtitleMenu() async {
    final tracks = await _playerController.getSubtitleTracks();
    if (!mounted) return;
    _showTrackMenu('Subtitles', tracks, (idx) => _playerController.setSubtitleTrack(idx));
  }

  void _showAudioMenu() async {
    final tracks = await _playerController.getAudioTracks();
    if (!mounted) return;
    _showTrackMenu('Audio Tracks', tracks, (idx) => _playerController.setAudioTrack(idx));
  }

  void _showAspectRatioMenu() {
    final ratios = ['Fit', 'Fill', 'Stretch', '16:9', '4:3'];
    _showTrackMenu('Aspect Ratio', ratios, (idx) {
      // TODO: Implement aspect ratio change in controllers
    });
  }

  void _showTrackMenu(String title, List<String> items, Function(int) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D29),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(items[index], style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    onSelected(index);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _ShowControlsIntent extends Intent { const _ShowControlsIntent(); }
class _SeekBackIntent extends Intent { const _SeekBackIntent(); }
class _SeekForwardIntent extends Intent { const _SeekForwardIntent(); }
