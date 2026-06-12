import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeStorage {
  static const String _themeKey = 'selected_theme';

  static Future<void> saveTheme(AppThemeType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, type.name);
  }

  static Future<AppThemeType> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey);
    if (themeName == null) return AppThemeType.bingieNeon;
    return AppThemeType.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => AppThemeType.bingieNeon,
    );
  }
}
