import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WatchioFocusAction extends StatelessWidget {
  final Widget child;
  final VoidCallback? onActivate;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final MouseCursor? mouseCursor;

  const WatchioFocusAction({
    super.key,
    required this.child,
    this.onActivate,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
    this.mouseCursor,
  });

  static const Map<ShortcutActivator, Intent> activationShortcuts = {
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  };

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: autofocus,
      focusNode: focusNode,
      mouseCursor: mouseCursor ?? MouseCursor.defer,
      onFocusChange: onFocusChange,
      shortcuts: activationShortcuts,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onActivate?.call();
            return null;
          },
        ),
      },
      child: child,
    );
  }
}
