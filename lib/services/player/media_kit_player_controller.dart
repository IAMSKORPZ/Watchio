import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'app_player_controller.dart';
import '../app_state.dart';
import '../../models/playback_item.dart';
import '../../repositories/user_preferences.dart';
import '../../utils/get_playlist_type.dart';

class MediaKitPlayerController extends AppPlayerController {
  late Player _player;
  late VideoController _videoController;
  
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _playSub;
  StreamSubscription? _buffSub;
  StreamSubscription? _errSub;

  PlaybackItem? _currentItem;

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
  Future<void> initialize() async {
    final hardwareDecoding = await UserPreferences.getHardwareDecoding();
    _player = Player();
    
    if (hardwareDecoding && !kIsWeb) {
      try {
        // Safe way to set properties for native platforms without explicit cast that causes stub errors on web
        // Using dynamic to bypass static analysis for platform-specific methods
        final dynamic platform = _player.platform;
        if (platform.toString().contains('NativePlayer')) {
          await platform.setProperty('hwdec', 'auto');
        }
      } catch (e) {
        debugPrint('MediaKit: Could not set hardware decoding: $e');
      }
    }

    _videoController = VideoController(_player);
    
    _posSub = _player.stream.position.listen((p) {
      _position = p;
      notifyListeners();
    });
    
    _durSub = _player.stream.duration.listen((d) {
      _duration = d;
      notifyListeners();
    });
    
    _playSub = _player.stream.playing.listen((p) {
      _isPlaying = p;
      notifyListeners();
    });
    
    _buffSub = _player.stream.buffering.listen((b) {
      _isBuffering = b;
      notifyListeners();
    });

    _errSub = _player.stream.error.listen((e) {
      _error = e;
      notifyListeners();
    });

    _isInitialized = true;
    notifyListeners();
  }

  @override
  Future<void> setDataSource(PlaybackItem item) async {
    _error = null;
    _currentItem = item;
    final playlist = AppState.currentPlaylist;
    
    debugPrint('--- WATCHIO PLAYBACK PIPELINE AUDIT (MediaKit) ---');
    debugPrint('Provider Type: ${isXtreamCode ? "Xtream Codes" : (isM3u ? "M3U" : "Unknown")}');
    debugPrint('Playlist Name: ${playlist?.name ?? "NULL"}');
    debugPrint('Username: ${playlist?.username ?? "NULL"}');
    debugPrint('Server URL: ${playlist?.url ?? "NULL"}');
    debugPrint('Content Type: ${item.contentType}');
    debugPrint('Stream ID: ${item.id}');
    debugPrint('Generated URL: ${item.url}');
    debugPrint('User-Agent: ${item.headers['User-Agent']}');
    debugPrint('--------------------------------------------------');

    try {
      await _player.open(Media(item.url, httpHeaders: item.headers), play: true);
      debugPrint('LIVE TV PLAYER STARTED');
      if (item.startPosition > Duration.zero) {
        debugPrint('MediaKit: Resuming at ${item.startPosition}');
        await _player.seek(item.startPosition);
      }
    } catch (e) {
      debugPrint('MediaKit: CRITICAL FAILURE: $e');
      _error = 'Playback Failed: Unable to connect to stream';
      notifyListeners();
    }
  }

  @override
  Future<void> play() async => await _player.play();

  @override
  Future<void> pause() async => await _player.pause();

  @override
  Future<void> seek(Duration position) async => await _player.seek(position);

  @override
  Future<void> setVolume(double volume) async => await _player.setVolume(volume);

  @override
  Future<void> setAspectRatio(double? ratio) async {
    // media_kit supports aspect ratio via mpv properties if needed, 
    // but usually it's handled by the Video widget's fit property.
  }

  @override
  Future<List<String>> getAudioTracks() async {
    return _player.state.tracks.audio.map((t) => t.title ?? t.language ?? 'Unknown').toList();
  }

  @override
  Future<void> setAudioTrack(int index) async {
    await _player.setAudioTrack(_player.state.tracks.audio[index]);
  }

  @override
  Future<List<String>> getSubtitleTracks() async {
    return _player.state.tracks.subtitle.map((t) => t.title ?? t.language ?? 'Unknown').toList();
  }

  @override
  Future<void> setSubtitleTrack(int index) async {
    await _player.setSubtitleTrack(_player.state.tracks.subtitle[index]);
  }

  @override
  Widget buildPlayerView(BuildContext context) {
    return Video(controller: _videoController);
  }

  @override
  void dispose() {
    debugPrint('LIVE TV PLAYER STOPPED');
    try {
      _player.pause();
      _player.stop();
    } catch (_) {}
    _posSub?.cancel();
    _durSub?.cancel();
    _playSub?.cancel();
    _buffSub?.cancel();
    _errSub?.cancel();
    _player.dispose();
    debugPrint('LIVE TV PLAYER DISPOSED');
    super.dispose();
  }
}
