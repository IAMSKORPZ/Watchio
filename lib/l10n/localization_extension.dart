import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

extension AppLocalizationsExtension on BuildContext {
  // Returns AppLocalizations or null if not found
  AppLocalizations? get locMaybe => AppLocalizations.of(this);

  // Returns AppLocalizations, falls back to a dummy if not found to prevent crashes
  AppLocalizations get loc => AppLocalizations.of(this)!;
}
