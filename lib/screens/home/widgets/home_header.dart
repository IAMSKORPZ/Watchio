import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/watchio_focus_action.dart';
import '../../../utils/responsive_helper.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onProfile;
  final VoidCallback onSports;
  final VoidCallback? onAnnouncements;

  const HomeHeader({
    super.key,
    required this.onSearch,
    required this.onProfile,
    required this.onSports,
    this.onAnnouncements,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final isDesktop = deviceType == DeviceType.desktop;
    final isTablet = deviceType == DeviceType.tablet;

    const double logoHeight = 110;
    double timeFontSize = isDesktop ? 44 : (isTablet ? 28 : 22);
    double dateFontSize = isDesktop ? 18 : (isTablet ? 14 : 12);
    double iconSize = isDesktop ? 36 : (isTablet ? 28 : 24);

    return Row(
      children: [
        // LEFT: Logo
        SizedBox(
          height: 60,
          width: logoHeight * 1.5,
          child: OverflowBox(
            maxHeight: logoHeight,
            child: Image.asset(
              'assets/images/App_Logo.png',
              height: logoHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.play_arrow_rounded,
                color: const Color(0xFF00B7FF),
                size: logoHeight * 0.7,
              ),
            ),
          ),
        ),

        const Spacer(),

        // CENTER: Time & Date
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              DateFormat('hh:mm a').format(now),
              style: TextStyle(
                color: Colors.white,
                fontSize: timeFontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              DateFormat('MMM d, yyyy').format(now),
              style: TextStyle(
                color: const Color(0xFFC12CFF),
                fontSize: dateFontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        const Spacer(),

        // RIGHT: Floating Navigation Icons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Bar Area
            _ToolbarItem(
              onTap: onSearch,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 20 : 12,
                  vertical: isDesktop ? 12 : 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: iconSize,
                    ),
                    SizedBox(width: isDesktop ? 14 : 10),
                    Text(
                      'SEARCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 20 : 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: isDesktop ? 12 : 8),
            _ToolbarItem(
              icon: Icons.sports_soccer_rounded,
              iconSize: iconSize,
              onTap: onSports,
            ),
            _ToolbarItem(
              icon: Icons.notifications_rounded,
              iconSize: iconSize,
              onTap: onAnnouncements ?? () {},
            ),
          ],
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return WatchioFocusAction(
      onFocusChange: (val) => setState(() => _isFocused = val),
      onActivate: widget.onTap,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedScale(
          scale: _isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.hideLabel ? 12 : 18,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: _isFocused
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? const Color(0xFFC12CFF)
                    : Colors.white.withValues(alpha: 0.1),
                width: _isFocused ? 2.5 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFFC12CFF).withValues(alpha: 0.3),
                        blurRadius: 15,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  color: _isFocused ? Colors.white : Colors.white70,
                  size: 20,
                ),
                if (!widget.hideLabel) ...[
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: _isFocused ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarItem extends StatefulWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback onTap;
  final double iconSize;

  const _ToolbarItem({
    this.icon,
    this.child,
    required this.onTap,
    this.iconSize = 22,
  });

  @override
  State<_ToolbarItem> createState() => _ToolbarItemState();
}

class _ToolbarItemState extends State<_ToolbarItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ), // Further increased spacing for polish
      child: WatchioFocusAction(
        onFocusChange: (val) => setState(() => _isFocused = val),
        onActivate: widget.onTap,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: widget.child != null
                ? EdgeInsets.zero
                : const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: widget.child != null
                  ? BoxShape.rectangle
                  : BoxShape.circle,
              color: _isFocused
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: widget.child != null
                  ? BorderRadius.circular(30)
                  : null,
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFFC12CFF).withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            child:
                widget.child ??
                Icon(
                  widget.icon,
                  color: _isFocused ? Colors.white : Colors.white70,
                  size: widget.iconSize,
                ),
          ),
        ),
      ),
    );
  }
}
