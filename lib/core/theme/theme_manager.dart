import 'package:flutter/material.dart';
import '../../repositories/user_preferences.dart';
import 'app_theme.dart';
import 'theme_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  AppThemeType _currentThemeType = AppThemeType.bingieNeon;
  ThemeMode _themeMode = ThemeMode.dark;
  String _backgroundStyle = 'dynamic';
  String _tileStyle = 'rounded';
  bool _animationsEnabled = true;

  AppThemeType get currentThemeType => _currentThemeType;
  ThemeMode get themeMode => _themeMode;
  String get backgroundStyle => _backgroundStyle;
  String get tileStyle => _tileStyle;
  bool get animationsEnabled => _animationsEnabled;
  bool get showBackgroundImage => _backgroundStyle == 'dynamic';
  double get tileRadius => _tileStyle == 'compact' ? 16 : 30;

  ThemeData get currentThemeData => AppTheme.getTheme(_currentThemeType);

  ThemeManager() {
    _init();
  }

  Future<void> _init() async {
    _currentThemeType = await ThemeStorage.loadTheme();
    _themeMode = await UserPreferences.getThemeMode();
    final prefs = await SharedPreferences.getInstance();
    _backgroundStyle = prefs.getString('appearance_background') ?? 'dynamic';
    _tileStyle = prefs.getString('appearance_tiles') ?? 'rounded';
    _animationsEnabled = prefs.getBool('appearance_animations') ?? true;
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

  Future<void> setBackgroundStyle(String value) async {
    _backgroundStyle = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appearance_background', value);
    notifyListeners();
  }

  Future<void> setTileStyle(String value) async {
    _tileStyle = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appearance_tiles', value);
    notifyListeners();
  }

  Future<void> setAnimationsEnabled(bool value) async {
    _animationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appearance_animations', value);
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
