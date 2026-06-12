import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onProfile;
  final VoidCallback onAbout;

  const HomeHeader({
    super.key,
    required this.onSearch,
    required this.onProfile,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 700;
        final bool isTV = constraints.maxWidth >= 1600;
        
        double logoHeight;
        if (isSmall) {
          logoHeight = 65;
        } else if (isTV) {
          logoHeight = 110;
        } else {
          logoHeight = 85;
        }
        
        return Row(
          children: [
            // Left: Logo
            Image.asset(
              'assets/images/App_Logo.png',
              height: logoHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.play_arrow_rounded, color: Color(0xFF00B7FF), size: 48),
            ),
            const Spacer(),
            // Center: Time & Date
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  DateFormat('hh:mm a').format(now),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(now),
                  style: const TextStyle(
                    color: Color(0xFFC12CFF), 
                    fontSize: 13, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Right: Actions
            Row(
              children: [
                HeaderButton(
                  icon: Icons.search_rounded, 
                  label: 'SEARCH', 
                  onTap: onSearch,
                  hideLabel: isSmall,
                ),
                HeaderButton(
                  icon: Icons.person_outline_rounded, 
                  label: 'PROFILE', 
                  onTap: onProfile,
                  hideLabel: isSmall,
                ),
                HeaderButton(
                  icon: Icons.info_outline_rounded, 
                  label: 'ABOUT', 
                  onTap: onAbout,
                  hideLabel: isSmall,
                ),
              ],
            ),
          ],
        );
      }
    );
  }
}

class HeaderButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hideLabel;

  const HeaderButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.hideLabel = false,
  });

  @override
  State<HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<HeaderButton> {
  bool _isFocused = false;
  bool _isHovered = false;

  bool get _isActive => _isFocused || _isHovered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: FocusableActionDetector(
        onFocusChange: (val) => setState(() => _isFocused = val),
        onShowHoverHighlight: (val) => setState(() => _isHovered = val),
        shortcuts: {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedScale(
            scale: _isActive ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: widget.hideLabel ? 12 : 18, 
                vertical: 10
              ),
              decoration: BoxDecoration(
                color: _isActive ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isActive ? const Color(0xFF00B7FF) : Colors.white.withValues(alpha: 0.1),
                  width: _isActive ? 2.5 : 1.0,
                ),
                boxShadow: _isActive ? [
                  BoxShadow(
                    color: const Color(0xFF00B7FF).withValues(alpha: 0.3),
                    blurRadius: 15,
                  )
                ] : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon, 
                    color: _isActive ? const Color(0xFF00B7FF) : Colors.white70, 
                    size: 20
                  ),
                  if (!widget.hideLabel) ...[
                    const SizedBox(width: 10),
                    Text(
                      widget.label, 
                      style: TextStyle(
                        color: _isActive ? Colors.white : Colors.white70, 
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      )
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
