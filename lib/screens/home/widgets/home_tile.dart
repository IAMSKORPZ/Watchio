import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/responsive_helper.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/theme_manager.dart';
import 'package:provider/provider.dart';

class HomeTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final bool autofocus;

  const HomeTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  State<HomeTile> createState() => _HomeTileState();
}

class _HomeTileState extends State<HomeTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ThemeManager>();
    final panelGradient = BingieThemeExtension.of(context).panelGradient;
    return FocusableActionDetector(
      autofocus: widget.autofocus,
      onFocusChange: (value) => setState(() => _isFocused = value),
      child: AnimatedScale(
        scale: manager.animationsEnabled && _isFocused ? 1.05 : 1.0,
        duration: Duration(milliseconds: manager.animationsEnabled ? 200 : 0),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _isFocused
                    ? widget.accentColor
                    : widget.accentColor.withValues(
                        alpha: 0.4,
                      ), // 2px consistent border (Requirement)
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withValues(
                    alpha: _isFocused ? 0.4 : 0.08,
                  ), // Reduced glow (Requirement)
                  blurRadius: _isFocused ? 25 : 12,
                  spreadRadius: _isFocused ? 2 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: panelGradient,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final deviceType = ResponsiveHelper.getDeviceType(
                        context,
                      );
                      final isDesktop = deviceType == DeviceType.desktop;
                      final isTablet = deviceType == DeviceType.tablet;

                      // Dynamically adjust sizes based on available height
                      final double h = constraints.maxHeight;

                      double iconSize = (h * 0.3).clamp(32.0, 64.0);
                      double titleSize = (h * 0.12).clamp(16.0, 24.0);
                      double subtitleSize = (h * 0.06).clamp(10.0, 12.0);
                      double spacing = (h * 0.05).clamp(4.0, 12.0);

                      if (isDesktop) {
                        iconSize = 72;
                        titleSize = 32;
                        subtitleSize = 16;
                        spacing = 16;
                      } else if (isTablet) {
                        iconSize = 60;
                        titleSize = 26;
                        subtitleSize = 13;
                        spacing = 10;
                      }

                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(isDesktop ? 24 : 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              widget.icon,
                              color: widget.accentColor,
                              size: iconSize,
                            ),
                            SizedBox(height: spacing),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            SizedBox(height: isDesktop ? 8 : 4),
                            Text(
                              widget.subtitle,
                              textAlign: TextAlign.center,
                              maxLines:
                                  1, // Keep it to 1 line to ensure it fits
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: subtitleSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
