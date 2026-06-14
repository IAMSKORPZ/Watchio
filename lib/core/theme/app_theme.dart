import 'package:flutter/material.dart';
import 'theme_extensions.dart';

enum AppThemeType {
  bingieNeon,
  emerald,
  crimson,
  ocean,
  gold,
  midnight,
  amoled,
  custom,
}

class AppTheme {
  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.emerald:
        return _buildTheme(
          primary: const Color(0xFF0BA360),
          secondary: const Color(0xFF3CBA92),
          primaryGradient: const LinearGradient(
            colors: [Color(0xFF0BA360), Color(0xFF3CBA92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case AppThemeType.crimson:
        return _buildTheme(
          primary: const Color(0xFFFF0844),
          secondary: const Color(0xFFFFB199),
          primaryGradient: const LinearGradient(
            colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case AppThemeType.ocean:
        return _buildTheme(
          primary: const Color(0xFF2575FC),
          secondary: const Color(0xFF6A11CB),
          primaryGradient: const LinearGradient(
            colors: [Color(0xFF2575FC), Color(0xFF6A11CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case AppThemeType.gold:
        return _buildTheme(
          primary: const Color(0xFFF6D365),
          secondary: const Color(0xFFFDA085),
          primaryGradient: const LinearGradient(
            colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case AppThemeType.midnight:
        return _buildTheme(
          primary: const Color(0xFF243B55),
          secondary: const Color(0xFF141E30),
          primaryGradient: const LinearGradient(
            colors: [Color(0xFF243B55), Color(0xFF141E30)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case AppThemeType.amoled:
        return _buildTheme(
          primary: const Color(0xFF6A11CB),
          secondary: const Color(0xFF2575FC),
          background: Colors.black,
          surface: const Color(0xFF121212),
          primaryGradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case AppThemeType.bingieNeon:
      default:
        return _buildTheme(
          primary: const Color(0xFF6A11CB),
          secondary: const Color(0xFF2575FC),
          primaryGradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
    }
  }

  static ThemeData _buildTheme({
    required Color primary,
    required Color secondary,
    required LinearGradient primaryGradient,
    Color background = const Color(0xFF0A0E21),
    Color surface = const Color(0xFF1D1E33),
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xCC1A1A2A), // Semi-transparent surface
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xAA30274F), // Standard glass bottom color as base
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xEE1A1A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      extensions: [
        BingieThemeExtension(
          primaryGradient: primaryGradient,
          secondaryGradient: LinearGradient(
            colors: [secondary, primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          glassColor: const Color(0xAA4A3D6A),
          glassBorder: Colors.white.withValues(alpha: 0.15),
        ),
      ],
      fontFamily: 'Roboto',
    );
  }
}
