import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.padding,
    this.border,
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
            color: theme.glassColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(color: theme.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
