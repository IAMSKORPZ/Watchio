import 'package:flutter/material.dart';

class BingieThemeExtension extends ThemeExtension<BingieThemeExtension> {
  final LinearGradient primaryGradient;
  final LinearGradient secondaryGradient;
  final LinearGradient panelGradient;
  final Color glassColor;
  final Color glassBorder;

  const BingieThemeExtension({
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.panelGradient,
    required this.glassColor,
    required this.glassBorder,
  });

  @override
  ThemeExtension<BingieThemeExtension> copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? secondaryGradient,
    LinearGradient? panelGradient,
    Color? glassColor,
    Color? glassBorder,
  }) {
    return BingieThemeExtension(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      panelGradient: panelGradient ?? this.panelGradient,
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
      primaryGradient: LinearGradient.lerp(
        primaryGradient,
        other.primaryGradient,
        t,
      )!,
      secondaryGradient: LinearGradient.lerp(
        secondaryGradient,
        other.secondaryGradient,
        t,
      )!,
      panelGradient: LinearGradient.lerp(
        panelGradient,
        other.panelGradient,
        t,
      )!,
      glassColor: Color.lerp(glassColor, other.glassColor, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }

  static BingieThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<BingieThemeExtension>() ?? defaults;
  }

  static const defaults = BingieThemeExtension(
    primaryGradient: LinearGradient(
      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
    ),
    secondaryGradient: LinearGradient(
      colors: [Color(0xFF2575FC), Color(0xFF6A11CB)],
    ),
    panelGradient: LinearGradient(
      colors: [Color(0xAA4A3D6A), Color(0xAA30274F)],
    ),
    glassColor: Color(0x1AFFFFFF),
    glassBorder: Color(0x1AFFFFFF),
  );
}
