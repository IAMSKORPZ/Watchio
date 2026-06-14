import 'package:flutter/material.dart';

class BingieThemeExtension extends ThemeExtension<BingieThemeExtension> {
  final LinearGradient primaryGradient;
  final LinearGradient secondaryGradient;
  final Color glassColor;
  final Color glassBorder;

  const BingieThemeExtension({
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.glassColor,
    required this.glassBorder,
  });

  @override
  ThemeExtension<BingieThemeExtension> copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? secondaryGradient,
    Color? glassColor,
    Color? glassBorder,
  }) {
    return BingieThemeExtension(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      glassColor: glassColor ?? this.glassColor,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  ThemeExtension<BingieThemeExtension> lerp(
    ThemeExtension<BingieThemeExtension>? other,
    double t,
  ) {
    if (other is! BingieThemeExtension) {
      return this;
    }
    return BingieThemeExtension(
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      secondaryGradient: LinearGradient.lerp(secondaryGradient, other.secondaryGradient, t)!,
      glassColor: Color.lerp(glassColor, other.glassColor, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }

  static BingieThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<BingieThemeExtension>() ?? defaults;
  }

  static const defaults = BingieThemeExtension(
    primaryGradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
    secondaryGradient: LinearGradient(colors: [Color(0xFF2575FC), Color(0xFF6A11CB)]),
    glassColor: Color(0xAA4A3D6A), // Default to new standard top color
    glassBorder: Color(0x33FFFFFF),
  );

  LinearGradient get glassGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xAA4A3D6A),
          Color(0xAA30274F),
        ],
      );
}
