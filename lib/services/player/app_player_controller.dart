import 'package:flutter/widgets.dart';
import '../../models/playback_item.dart';

abstract class AppPlayerController extends ChangeNotifier {
  bool get isInitialized;
  bool get isPlaying;
  bool get isBuffering;
  Duration get position;
  Duration get duration;
  String? get error;
  double? get aspectRatio;

  PlaybackItem? get currentItem;

  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setDataSource(PlaybackItem item);
  Future<void> setVolume(double volume);
  Future<void> setAspectRatio(double? ratio);
  
  // Track selection
  Future<List<String>> getAudioTracks();
  Future<void> setAudioTrack(int index);
  Future<List<String>> getSubtitleTracks();
  Future<void> setSubtitleTrack(int index);

  Widget buildPlayerView(BuildContext context, {BoxFit? fit});

  @override
  void dispose();
}
