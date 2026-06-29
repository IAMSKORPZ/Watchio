import 'package:flutter/foundation.dart';
import '../../models/player_engine.dart';
import 'app_player_controller.dart';
import 'media_kit_player_controller.dart';
import 'exoplayer_controller.dart';

class PlayerFactory {
  static AppPlayerController create(PlayerEngine engine) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return ExoPlayerController();
    }

    switch (engine) {
      case PlayerEngine.exoPlayer:
        return ExoPlayerController();
      case PlayerEngine.mediaKit:
        return MediaKitPlayerController();
      case PlayerEngine.auto:
        return MediaKitPlayerController();
      case PlayerEngine.vlc:
        // VLC fallback not implemented yet, using MediaKit
        return MediaKitPlayerController();
    }
  }
}
