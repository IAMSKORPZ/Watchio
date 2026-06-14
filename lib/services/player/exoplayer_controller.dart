import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'app_player_controller.dart';
import '../../models/playback_item.dart';

class ExoPlayerController extends AppPlayerController {
  VideoPlayerController? _controller;
  
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;
  PlaybackItem? _currentItem;
  double? _aspectRatio;
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
    _isInitialized = true;
    notifyListeners();
  }

  @override
  Future<void> setDataSource(PlaybackItem item) async {
    _error = null;
    _currentItem = item;
    _retryCount = 0;
    await _setupController(item);
  }

  Future<void> _setupController(PlaybackItem item) async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    final uri = Uri.tryParse(item.url);
    if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
      _error = 'Invalid stream URL';
      notifyListeners();
      return;
    }

    _controller = VideoPlayerController.networkUrl(
      uri,
      httpHeaders: item.headers,
    );

    _controller!.addListener(_updateState);

    try {
      await _controller!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );
      
      _duration = _controller!.value.duration;
      
      if (item.startPosition > Duration.zero) {
        await _controller!.seekTo(item.startPosition);
      }
      
      await _controller!.play();
    } catch (e) {
      debugPrint('ExoPlayer Error: $e');
      if (_retryCount < _maxRetries) {
        _retryCount++;
        debugPrint('ExoPlayer: Retrying... ($_retryCount/$_maxRetries)');
        await Future.delayed(const Duration(seconds: 2));
        await _setupController(item);
      } else {
        _error = 'Playback Error: $e';
        notifyListeners();
      }
    }
  }

  void _updateState() {
    if (_controller == null) return;
    
    final value = _controller!.value;
    
    if (value.hasError) {
      debugPrint('ExoPlayer Controller Error: ${value.errorDescription}');
      _error = value.errorDescription;
    }

    _isPlaying = value.isPlaying;
    _isBuffering = value.isBuffering;
    _position = value.position;
    
    notifyListeners();
  }

  @override
  Future<void> play() async => await _controller?.play();

  @override
  Future<void> pause() async => await _controller?.pause();

  @override
  Future<void> seek(Duration position) async => await _controller?.seekTo(position);

  @override
  Future<void> setVolume(double volume) async => await _controller?.setVolume(volume / 100.0);

  @override
  Future<void> setAspectRatio(double? ratio) async {
    _aspectRatio = ratio;
    notifyListeners();
  }

  @override
  Future<List<String>> getAudioTracks() async => ['Default'];

  @override
  Future<void> setAudioTrack(int index) async {}

  @override
  Future<List<String>> getSubtitleTracks() async => ['None'];

  @override
  Future<void> setSubtitleTrack(int index) async {}

  @override
  Widget buildPlayerView(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    
    Widget player = VideoPlayer(_controller!);
    
    if (_aspectRatio != null) {
      player = AspectRatio(
        aspectRatio: _aspectRatio!,
        child: player,
      );
    } else {
      player = AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: player,
      );
    }

    return Center(child: player);
  }

  @override
  void dispose() {
    _controller?.removeListener(_updateState);
    _controller?.dispose();
    super.dispose();
  }
}
