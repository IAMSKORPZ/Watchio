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
  Future<void> initialize() async {
    // Basic initialization, actual controller created in setDataSource
    _isInitialized = true;
    notifyListeners();
  }

  @override
  Future<void> setDataSource(PlaybackItem item) async {
    _error = null;
    if (_controller != null) {
      await _controller!.dispose();
    }

    debugPrint('--- PLAYBACK START ---');
    debugPrint('Title: ${item.title}');
    debugPrint('Type: ${item.contentType}');
    debugPrint('URL: ${item.url}');
    debugPrint('Headers: ${item.headers}');
    debugPrint('---');

    if (item.url.isEmpty) {
      _error = 'Playback URL is empty';
      notifyListeners();
      return;
    }

    final uri = Uri.tryParse(item.url);
    if (uri == null) {
      debugPrint('ExoPlayer: Invalid URL: ${item.url}');
      _error = 'Invalid Stream URL';
      notifyListeners();
      return;
    }

    _controller = VideoPlayerController.networkUrl(
      uri,
      httpHeaders: item.headers,
    );

    try {
      await _controller!.initialize();
      _duration = _controller!.value.duration;
      
      _controller!.addListener(_updateState);
      
      if (item.startPosition > Duration.zero) {
        await _controller!.seekTo(item.startPosition);
      }
      
      await _controller!.play();
      debugPrint('ExoPlayer: Playback started successfully');
    } catch (e) {
      debugPrint('ExoPlayer Initialization Error: $e');
      _error = 'Failed to initialize player: $e';
      notifyListeners();
    }
  }

  void _updateState() {
    if (_controller == null) return;
    
    if (_controller!.value.hasError) {
      debugPrint('ExoPlayer State Error: ${_controller!.value.errorDescription}');
    }

    _isPlaying = _controller!.value.isPlaying;
    _isBuffering = _controller!.value.isBuffering;
    _position = _controller!.value.position;
    _error = _controller!.value.hasError ? _controller!.value.errorDescription : null;
    
    notifyListeners();
  }

  @override
  Future<void> play() async => await _controller?.play();

  @override
  Future<void> pause() async => await _controller?.pause();

  @override
  Future<void> seek(Duration position) async => await _controller?.seekTo(position);

  @override
  Future<void> setVolume(double volume) async => await _controller?.setVolume(volume);

  @override
  Future<void> setAspectRatio(double? ratio) async {
    // Standard video_player doesn't easily support dynamic aspect ratio override on the controller itself,
    // usually handled by AspectRatio widget in buildPlayerView.
  }

  @override
  Future<List<String>> getAudioTracks() async {
    // video_player doesn't easily expose multiple audio tracks in Dart yet
    return ['Default'];
  }

  @override
  Future<void> setAudioTrack(int index) async {
    // Not supported in basic video_player
  }

  @override
  Future<List<String>> getSubtitleTracks() async {
    return ['None'];
  }

  @override
  Future<void> setSubtitleTrack(int index) async {
    // Not supported in basic video_player
  }

  @override
  Widget buildPlayerView(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_updateState);
    _controller?.dispose();
    super.dispose();
  }
}
