import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../utils/get_playlist_type.dart';
import '../app_state.dart';
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
    // Basic initialization, actual controller created in setDataSource
    _isInitialized = true;
    notifyListeners();
  }

  @override
  Future<void> setDataSource(PlaybackItem item) async {
    _error = null;
    _currentItem = item;
    if (_controller != null) {
      debugPrint('ExoPlayer: Disposing previous controller');
      await _controller!.dispose();
      _controller = null;
    }

    final playlist = AppState.currentPlaylist;
    debugPrint('--- WATCHIO PLAYBACK PIPELINE AUDIT ---');
    debugPrint('Provider Type: ${isXtreamCode ? "Xtream Codes" : (isM3u ? "M3U" : "Unknown")}');
    debugPrint('Playlist Name: ${playlist?.name ?? "NULL"}');
    debugPrint('Username: ${playlist?.username ?? "NULL"}');
    debugPrint('Server URL: ${playlist?.url ?? "NULL"}');
    debugPrint('Content Type: ${item.contentType}');
    debugPrint('Stream ID: ${item.id}');
    debugPrint('Generated URL: ${item.url}');
    debugPrint('User-Agent: ${item.headers['User-Agent']}');
    debugPrint('Referer: ${item.headers['Referer']}');
    debugPrint('---------------------------------------');

    if (item.url.isEmpty || item.url == item.id) {
      debugPrint('ExoPlayer: REJECTED - URL is empty or matches ID (Generation failed)');
      _error = 'Playback Failed: Invalid stream configuration';
      notifyListeners();
      return;
    }

    final uri = Uri.tryParse(item.url);
    if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
      debugPrint('ExoPlayer: REJECTED - Invalid URI format: ${item.url}');
      _error = 'Playback Failed: Invalid stream URL format';
      notifyListeners();
      return;
    }

    _controller = VideoPlayerController.networkUrl(
      uri,
      httpHeaders: item.headers,
    );

    _controller!.addListener(_updateState);

    try {
      debugPrint('ExoPlayer: Initializing with Media3...');
      await _controller!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Stream connection timed out (15s)');
        },
      );
      
      _duration = _controller!.value.duration;
      debugPrint('ExoPlayer: Initialized Successfully. Duration: $_duration');
      debugPrint('LIVE TV PLAYER STARTED');
      
      if (item.startPosition > Duration.zero) {
        debugPrint('ExoPlayer: Resuming at ${item.startPosition}');
        await _controller!.seekTo(item.startPosition);
      }
      
      await _controller!.play();
      debugPrint('ExoPlayer: Playing');
    } catch (e) {
      debugPrint('ExoPlayer: CRITICAL FAILURE');
      debugPrint('Error Details: $e');
      _error = 'Playback Failed: Unable to connect to stream';
      
      try {
        await _controller?.dispose();
        _controller = null;
      } catch (_) {}
      
      notifyListeners();
    }
  }

  void _updateState() {
    if (_controller == null) return;
    
    final value = _controller!.value;
    
    if (value.hasError) {
      debugPrint('ExoPlayer Error Event: ${value.errorDescription}');
    }

    if (_isBuffering != value.isBuffering) {
      debugPrint('ExoPlayer State: ${value.isBuffering ? "BUFFERING" : "READY"}');
    }

    _isPlaying = value.isPlaying;
    _isBuffering = value.isBuffering;
    _position = value.position;
    
    if (value.hasError) {
       _error = 'Playback Failed: Source error';
    }
    
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
      return const SizedBox.shrink(); // Let the parent screen show the loading state
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
    debugPrint('LIVE TV PLAYER STOPPED');
    _controller?.pause();
    _controller?.removeListener(_updateState);
    _controller?.dispose();
    debugPrint('LIVE TV PLAYER DISPOSED');
    super.dispose();
  }
}
