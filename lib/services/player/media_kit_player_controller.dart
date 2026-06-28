import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'app_player_controller.dart';
import '../../models/playback_item.dart';
import '../../repositories/user_preferences.dart';

class MediaKitPlayerController extends AppPlayerController {
  late Player _player;
  late VideoController _videoController;

  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;
  PlaybackItem? _currentItem;
  double? _aspectRatio;

  bool _disposed = false;
  int _requestId = 0;
  Timer? _retryTimer;
  DateTime _lastPositionNotify = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _lastNotifiedPosition = Duration.zero;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _playSub;
  StreamSubscription? _buffSub;
  StreamSubscription? _errSub;

  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  bool get isInitialized => _isInitialized;
  @override
  bool get isPlaying => _isPlaying;
  @override
  bool get isBuffering => _isBuffering;
  @override
  Duration get position => _position;
  @override
  Duration get duration => _duration;
  @override
  String? get error => _error;
  @override
  PlaybackItem? get currentItem => _currentItem;
  @override
  double? get aspectRatio => _aspectRatio;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  Future<void> initialize() async {
    if (_disposed) return;
    debugPrint('MediaKit: Player Created');
    final hardwareDecoding = await UserPreferences.getHardwareDecoding();
    _player = Player();

    if (hardwareDecoding && !kIsWeb) {
      try {
        final dynamic platform = _player.platform;
        if (platform.toString().contains('NativePlayer')) {
          await platform.setProperty('hwdec', 'auto');
        }
      } catch (e) {
        debugPrint('MediaKit: Hardware decoding error: $e');
      }
    }

    _videoController = VideoController(_player);

    _posSub = _player.stream.position.listen((p) {
      if (_disposed) return;
      _position = p;
      final now = DateTime.now();
      final movedBy = (p - _lastNotifiedPosition).abs();
      if (now.difference(_lastPositionNotify) >=
              const Duration(milliseconds: 750) ||
          movedBy >= const Duration(seconds: 2)) {
        _lastPositionNotify = now;
        _lastNotifiedPosition = p;
        notifyListeners();
      }
    });

    _durSub = _player.stream.duration.listen((d) {
      if (_disposed) return;
      _duration = d;
      notifyListeners();
    });

    _playSub = _player.stream.playing.listen((p) {
      if (_disposed) return;
      _isPlaying = p;
      if (p) debugPrint('MediaKit: Playback Started');
      notifyListeners();
    });

    _buffSub = _player.stream.buffering.listen((b) {
      if (_disposed) return;
      _isBuffering = b;
      notifyListeners();
    });

    _errSub = _player.stream.error.listen((e) {
      if (_disposed) return;
      debugPrint('MediaKit Stream Error: $e');
      _error = e;
      notifyListeners();
    });

    _isInitialized = true;
    notifyListeners();
  }

  @override
  Future<void> setDataSource(PlaybackItem item) async {
    if (_disposed) return;
    _requestId++;
    debugPrint('MediaKit: Player Opened -> ${item.title} (Req: $_requestId)');
    _error = null;
    _currentItem = item;
    _retryCount = 0;
    _retryTimer?.cancel();
    await _openMedia(item, _requestId);
  }

  Future<void> _openMedia(PlaybackItem item, int requestId) async {
    if (_disposed || requestId != _requestId) return;

    try {
      await _player
          .open(Media(item.url, httpHeaders: item.headers), play: true)
          .timeout(const Duration(seconds: 15));

      if (_disposed || requestId != _requestId) return;

      if (item.startPosition > Duration.zero) {
        await _player.seek(item.startPosition);
      }
    } catch (e) {
      if (_disposed || requestId != _requestId) {
        debugPrint(
          'MediaKit: Ignoring error from stale request or disposed controller',
        );
        return;
      }

      debugPrint('MediaKit Error: $e');
      if (_retryCount < _maxRetries) {
        _retryCount++;
        debugPrint('MediaKit: Retrying... ($_retryCount/$_maxRetries)');
        _retryTimer?.cancel();
        _retryTimer = Timer(const Duration(seconds: 2), () {
          if (!_disposed && requestId == _requestId) {
            _openMedia(item, requestId);
          } else {
            debugPrint('MediaKit: Retry cancelled - stale request or disposed');
          }
        });
      } else {
        debugPrint('Playback failed after max retries');
        debugPrint('Retry stopped - max retries reached');
        _error = 'Playback Error: $e';
        notifyListeners();
      }
    }
  }

  @override
  Future<void> play() async {
    if (_disposed) return;
    await _player.play();
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    _requestId++;
    _retryTimer?.cancel();
    _error = null;
    _currentItem = null;
    await _player.stop();
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    if (_disposed) return;
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_disposed) return;
    await _player.seek(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    await _player.setVolume(volume);
  }

  @override
  Future<void> setAspectRatio(double? ratio) async {
    if (_disposed) return;
    _aspectRatio = ratio;
    // For media_kit, we can also set the property on mpv
    if (!kIsWeb) {
      try {
        final dynamic platform = _player.platform;
        if (platform.toString().contains('NativePlayer')) {
          if (ratio != null) {
            await platform.setProperty(
              'video-aspect-override',
              ratio.toString(),
            );
          } else {
            await platform.setProperty('video-aspect-override', '-1');
          }
        }
      } catch (e) {
        debugPrint('MediaKit: Could not set aspect ratio property: $e');
      }
    }
    notifyListeners();
  }

  @override
  Future<List<String>> getAudioTracks() async {
    if (_disposed) return [];
    return _player.state.tracks.audio
        .map((t) => t.title ?? t.language ?? 'Audio track')
        .toList();
  }

  @override
  Future<void> setAudioTrack(int index) async {
    if (_disposed) return;
    await _player.setAudioTrack(_player.state.tracks.audio[index]);
  }

  @override
  Future<List<String>> getSubtitleTracks() async {
    if (_disposed) return [];
    return _player.state.tracks.subtitle
        .map((t) => t.title ?? t.language ?? 'Subtitle')
        .toList();
  }

  @override
  Future<void> setSubtitleTrack(int index) async {
    if (_disposed) return;
    await _player.setSubtitleTrack(_player.state.tracks.subtitle[index]);
  }

  @override
  Widget buildPlayerView(BuildContext context, {BoxFit? fit}) {
    if (_disposed) return const SizedBox.shrink();
    return Video(
      controller: _videoController,
      fill: _aspectRatio != null || fit != null
          ? Colors.black
          : Colors.transparent,
      fit: fit ?? (_aspectRatio != null ? BoxFit.fill : BoxFit.contain),
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    debugPrint('MediaKit: Player Disposing (Req: $_requestId)');
    _disposed = true;
    _requestId++;
    _retryTimer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _playSub?.cancel();
    _buffSub?.cancel();
    _errSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
