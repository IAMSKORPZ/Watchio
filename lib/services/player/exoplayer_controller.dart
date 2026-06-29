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

  bool _disposed = false;
  int _requestId = 0;
  Timer? _retryTimer;
  DateTime _lastPositionNotify = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _lastNotifiedPosition = Duration.zero;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

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
    if (_disposed) return;
    debugPrint('ExoPlayer: Player Created');
    _isInitialized = true;
    notifyListeners();
  }

  @override
  Future<void> setDataSource(PlaybackItem item) async {
    if (_disposed) return;
    _requestId++;
    debugPrint('ExoPlayer: Player Opened -> ${item.title} (Req: $_requestId)');
    _error = null;
    _currentItem = item;
    _retryCount = 0;
    _retryTimer?.cancel();
    await _setupController(item, _requestId);
  }

  Future<void> _setupController(PlaybackItem item, int requestId) async {
    if (_disposed || requestId != _requestId) {
      debugPrint(
        'ExoPlayer: Ignoring setup for stale request or disposed controller',
      );
      return;
    }

    if (_controller != null) {
      debugPrint('ExoPlayer: Player Closed (Disposing old controller)');
      _controller!.removeListener(_updateState);
      final oldController = _controller;
      _controller = null;
      await oldController!.dispose();
    }

    if (_disposed || requestId != _requestId) return;

    final uri = Uri.tryParse(item.url);
    if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
      debugPrint(
        'ExoPlayer: Playback Error -> Invalid stream URL: ${item.url}',
      );
      _error = 'Invalid stream URL';
      notifyListeners();
      return;
    }

    debugPrint('ExoPlayer: Initializing Source -> ${item.url}');
    final newController = VideoPlayerController.networkUrl(
      uri,
      httpHeaders: item.headers,
    );

    _controller = newController;
    _controller!.addListener(_updateState);

    try {
      await _controller!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
            'ExoPlayer: TimeoutException -> Connection timed out after 15s',
          );
          throw TimeoutException('Connection timed out');
        },
      );

      if (_disposed || requestId != _requestId) {
        debugPrint(
          'ExoPlayer: Ignoring successful init - request changed or disposed',
        );
        return;
      }

      debugPrint('ExoPlayer: Playback Started');
      _duration = _controller!.value.duration;

      if (item.startPosition > Duration.zero) {
        await _controller!.seekTo(item.startPosition);
      }

      if (!_disposed && requestId == _requestId) {
        await _controller!.play();
      }
    } catch (e) {
      if (_disposed || requestId != _requestId) {
        debugPrint(
          'ExoPlayer: Ignoring error from old request or disposed controller: $e',
        );
        return;
      }

      debugPrint('ExoPlayer Error: $e');
      if (_retryCount < _maxRetries) {
        _retryCount++;
        debugPrint('ExoPlayer: Retrying... ($_retryCount/$_maxRetries)');
        _retryTimer?.cancel();
        _retryTimer = Timer(const Duration(seconds: 2), () {
          if (!_disposed && requestId == _requestId) {
            _setupController(item, requestId);
          } else {
            debugPrint(
              'ExoPlayer: Retry cancelled - stale request or disposed',
            );
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

  void _updateState() {
    if (_disposed || _controller == null) return;

    final value = _controller!.value;

    if (value.hasError) {
      debugPrint('ExoPlayer Controller Error: ${value.errorDescription}');
      _error = value.errorDescription;
    }

    if (value.isBuffering != _isBuffering) {
      debugPrint(
        'ExoPlayer: Buffer State -> ${value.isBuffering ? "Buffering" : "Ready"}',
      );
    }

    final playingChanged = _isPlaying != value.isPlaying;
    final bufferingChanged = _isBuffering != value.isBuffering;

    _isPlaying = value.isPlaying;
    _isBuffering = value.isBuffering;
    _position = value.position;

    final now = DateTime.now();
    final movedBy = (_position - _lastNotifiedPosition).abs();
    final shouldNotifyPosition =
        now.difference(_lastPositionNotify) >=
            const Duration(milliseconds: 750) ||
        movedBy >= const Duration(seconds: 2);

    if (playingChanged || bufferingChanged || shouldNotifyPosition) {
      _lastPositionNotify = now;
      _lastNotifiedPosition = _position;
      notifyListeners();
    }
  }

  @override
  Future<void> play() async {
    if (_disposed) return;
    await _controller?.play();
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    _requestId++; // Invalidate any running async operations
    _retryTimer?.cancel();
    _error = null;
    _currentItem = null;
    if (_controller != null) {
      _controller!.removeListener(_updateState);
      final oldController = _controller;
      _controller = null;
      await oldController!.dispose();
    }
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    if (_disposed) return;
    await _controller?.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_disposed) return;
    await _controller?.seekTo(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    await _controller?.setVolume(volume / 100.0);
  }

  @override
  Future<void> setAspectRatio(double? ratio) async {
    if (_disposed) return;
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
  Widget buildPlayerView(BuildContext context, {BoxFit? fit}) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    Widget player = VideoPlayer(_controller!);

    if (fit != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: fit,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: player,
          ),
        ),
      );
    }

    if (_aspectRatio != null) {
      player = AspectRatio(aspectRatio: _aspectRatio!, child: player);
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
    if (_disposed) return;
    debugPrint('ExoPlayer: Player Disposing (Req: $_requestId)');
    _disposed = true;
    _requestId++; // Invalidate any running async operations
    _retryTimer?.cancel();
    _controller?.removeListener(_updateState);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
