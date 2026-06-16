import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/responsive_helper.dart';

class HomeBottomButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;

  const HomeBottomButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.accentColor = const Color(0xFFC12CFF),
  });

  @override
  State<HomeBottomButton> createState() => _HomeBottomButtonState();
}

class _HomeBottomButtonState extends State<HomeBottomButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final isDesktop = deviceType == DeviceType.desktop;
    final isTablet = deviceType == DeviceType.tablet;

    double fontSize = isDesktop ? 22 : (isTablet ? 18 : 16);
    double iconSize = isDesktop ? 28 : (isTablet ? 26 : 24);

    return FocusableActionDetector(
      onFocusChange: (val) => setState(() => _isFocused = val),
      child: AnimatedScale(
        scale: _isFocused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xAA4A3D6A), // Brighter purple-grey glass
                  const Color(0xAA30274F), // Brighter purple-grey glass
                ],
              ),
              borderRadius: BorderRadius.circular(isDesktop ? 24 : 30),
              border: Border.all(
                color: _isFocused ? widget.accentColor : Colors.transparent, // No colored borders in normal state
                width: 2.0,
              ),
              boxShadow: _isFocused ? [
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  // Ensure inner container also expands
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Keep content together
                    children: [
                      Icon(
                        widget.icon,
                        color: _isFocused ? widget.accentColor : Colors.white,
                        size: iconSize,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
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
