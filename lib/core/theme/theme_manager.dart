import 'package:flutter/material.dart';
import '../../repositories/user_preferences.dart';
import 'app_theme.dart';
import 'theme_storage.dart';

class ThemeManager extends ChangeNotifier {
  AppThemeType _currentThemeType = AppThemeType.bingieNeon;
  ThemeMode _themeMode = ThemeMode.dark;

  AppThemeType get currentThemeType => _currentThemeType;
  ThemeMode get themeMode => _themeMode;

  ThemeData get currentThemeData => AppTheme.getTheme(_currentThemeType);

  ThemeManager() {
    _init();
  }

  Future<void> _init() async {
    _currentThemeType = await ThemeStorage.loadTheme();
    _themeMode = await UserPreferences.getThemeMode();
    notifyListeners();
  }

  Future<void> setThemeType(AppThemeType type) async {
    _currentThemeType = type;
    await ThemeStorage.saveTheme(type);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await UserPreferences.setThemeMode(mode);
    notifyListeners();
  }

  // Legacy support aliases
  AppThemeType get selectedThemeType => _currentThemeType;
  // This helps when existing code expects a field named 'currentTheme' that is an enum
  AppThemeType get currentTheme => _currentThemeType; 
  Future<void> setAppTheme(AppThemeType type) => setThemeType(type);
  Future<void> setTheme(dynamic val) async {
    if (val is AppThemeType) {
      await setThemeType(val);
    } else if (val is ThemeMode) {
      await setThemeMode(val);
    }
  }
}
