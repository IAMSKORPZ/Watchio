import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/firestick_performance.dart';

class FocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scale;
  final bool showGlow;
  final BorderRadius borderRadius;
  final bool autofocus;

  const FocusWrapper({
    super.key,
    required this.child,
    this.onPressed,
    this.scale = 1.05,
    this.showGlow = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.autofocus = false,
  });

  @override
  State<FocusWrapper> createState() => _FocusWrapperState();
}

class _FocusWrapperState extends State<FocusWrapper> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onPressed?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isFocused ? perfScale(widget.scale) : 1.0,
          duration: perfDuration(const Duration(milliseconds: 200)),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: perfDuration(const Duration(milliseconds: 200)),
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: firestickPerformanceMode
                  ? null
                  : _isFocused && widget.showGlow
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
              border: Border.all(
                color: _isFocused ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
