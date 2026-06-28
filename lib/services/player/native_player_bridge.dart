import 'package:flutter/services.dart';

class NativePlayerBridge {
  static const MethodChannel _channel = MethodChannel('watchio/native_player');

  const NativePlayerBridge();

  Future<void> setBufferConfig({
    required int minBufferMs,
    required int maxBufferMs,
    required int playbackBufferMs,
    required int rebufferMs,
  }) {
    return _channel.invokeMethod('setBufferConfig', {
      'minBufferMs': minBufferMs,
      'maxBufferMs': maxBufferMs,
      'playbackBufferMs': playbackBufferMs,
      'rebufferMs': rebufferMs,
    });
  }

  Future<void> setLiveOffset({
    required int targetOffsetMs,
    required int minOffsetMs,
    required int maxOffsetMs,
  }) {
    return _channel.invokeMethod('setLiveOffset', {
      'targetOffsetMs': targetOffsetMs,
      'minOffsetMs': minOffsetMs,
      'maxOffsetMs': maxOffsetMs,
    });
  }

  Future<void> setPlaylistPreloadSeconds(int seconds) {
    return _channel.invokeMethod('setPlaylistPreloadSeconds', {
      'seconds': seconds,
    });
  }

  Future<void> attachMediaSession() {
    return _channel.invokeMethod('attachMediaSession');
  }

  Future<void> selectAudioTrack(int index) {
    return _channel.invokeMethod('selectAudioTrack', {'index': index});
  }

  Future<void> selectSubtitleTrack(int index) {
    return _channel.invokeMethod('selectSubtitleTrack', {'index': index});
  }
}
