import 'player_engine.dart';

enum PlayerAspectRatio {
  fit,
  fill,
  stretch,
  sixteenNine,
  fourThree,
}

class PlaybackSettings {
  final PlayerEngine engine;
  final bool hardwareDecoding;
  final String preferredAudioLanguage;
  final String preferredSubtitleLanguage;
  final PlayerAspectRatio aspectRatio;

  PlaybackSettings({
    this.engine = PlayerEngine.auto,
    this.hardwareDecoding = true,
    this.preferredAudioLanguage = 'en',
    this.preferredSubtitleLanguage = 'en',
    this.aspectRatio = PlayerAspectRatio.fit,
  });

  PlaybackSettings copyWith({
    PlayerEngine? engine,
    bool? hardwareDecoding,
    String? preferredAudioLanguage,
    String? preferredSubtitleLanguage,
    PlayerAspectRatio? aspectRatio,
  }) {
    return PlaybackSettings(
      engine: engine ?? this.engine,
      hardwareDecoding: hardwareDecoding ?? this.hardwareDecoding,
      preferredAudioLanguage: preferredAudioLanguage ?? this.preferredAudioLanguage,
      preferredSubtitleLanguage: preferredSubtitleLanguage ?? this.preferredSubtitleLanguage,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }
}
