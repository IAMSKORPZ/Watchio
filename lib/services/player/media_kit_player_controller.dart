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
  Future<void> initialize() async {
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
      debugPrint('MediaKit Stream Error: $e');
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
    _retryCount = 0;
    await _openMedia(item);
  }

  Future<void> _openMedia(PlaybackItem item) async {
    try {
      await _player.open(
        Media(item.url, httpHeaders: item.headers), 
        play: true
      ).timeout(const Duration(seconds: 15));
      
      if (item.startPosition > Duration.zero) {
        await _player.seek(item.startPosition);
      }
    } catch (e) {
      debugPrint('MediaKit Error: $e');
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(const Duration(seconds: 2));
        await _openMedia(item);
      } else {
        _error = 'Playback Error: $e';
        notifyListeners();
      }
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
    _aspectRatio = ratio;
    // For media_kit, we can also set the property on mpv
    if (!kIsWeb) {
      try {
        final dynamic platform = _player.platform;
        if (platform.toString().contains('NativePlayer')) {
          if (ratio != null) {
            await platform.setProperty('video-aspect-override', ratio.toString());
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
    return _player.state.tracks.audio.map((t) => t.title ?? t.language ?? 'Audio track').toList();
  }

  @override
  Future<void> setAudioTrack(int index) async {
    await _player.setAudioTrack(_player.state.tracks.audio[index]);
  }

  @override
  Future<List<String>> getSubtitleTracks() async {
    return _player.state.tracks.subtitle.map((t) => t.title ?? t.language ?? 'Subtitle').toList();
  }

  @override
  Future<void> setSubtitleTrack(int index) async {
    await _player.setSubtitleTrack(_player.state.tracks.subtitle[index]);
  }

  @override
  Widget buildPlayerView(BuildContext context) {
    return Video(
      controller: _videoController,
      fill: _aspectRatio != null ? Colors.black : Colors.transparent,
      fit: _aspectRatio != null ? BoxFit.fill : BoxFit.contain,
    );
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _playSub?.cancel();
    _buffSub?.cancel();
    _errSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
