import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';

const contentPanelGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xAA4A3D6A), Color(0xAA30274F)],
);

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;
  final Gradient? gradient;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.padding,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BingieThemeExtension.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null
                ? theme.glassColor.withValues(alpha: opacity)
                : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(color: theme.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
