import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onProfile;
  final VoidCallback onAbout;
  final VoidCallback onSports;
  final VoidCallback? onAnnouncements;

  const HomeHeader({
    super.key,
    required this.onSearch,
    required this.onProfile,
    required this.onAbout,
    required this.onSports,
    this.onAnnouncements,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Row(
      children: [
        // LEFT: Logo
        Image.asset(
          'assets/images/App_Logo.png',
          height: 70, // Increased from 60 (approx 15%+)
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.play_arrow_rounded, color: Color(0xFF00B7FF), size: 48),
        ),
        
        const Spacer(),
        
        // CENTER: Time & Date
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
                letterSpacing: 0.5,
              ),
            ),
            Text(
              DateFormat('MMM d, yyyy').format(now),
              style: const TextStyle(
                color: Color(0xFFC12CFF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        
        const Spacer(),
        
        // RIGHT: Floating Navigation Icons (Requirement: Remove blue container)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Bar Area
            _ToolbarItem(
              onTap: onSearch,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'SEARCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ToolbarItem(
              icon: Icons.sports_soccer_rounded,
              onTap: onSports,
            ),
            _ToolbarItem(
              icon: Icons.notifications_rounded,
              onTap: onAnnouncements ?? () {},
            ),
            _ToolbarItem(
              icon: Icons.info_outline_rounded,
              onTap: onAbout,
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
    return FocusableActionDetector(
      onFocusChange: (val) => setState(() => _isFocused = val),
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
                vertical: 10
            ),
            decoration: BoxDecoration(
              color: _isFocused ? const Color(0xAA4A3D6A) : const Color(0x44252525),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.1),
                width: _isFocused ? 2.0 : 1.0,
              ),
              boxShadow: _isFocused ? [
                BoxShadow(
                  color: const Color(0xFFC12CFF).withValues(alpha: 0.3),
                  blurRadius: 15,
                )
              ] : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  color: _isFocused ? Colors.white : Colors.white70,
                  size: 20
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
                    )
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

  const _ToolbarItem({
    this.icon,
    this.child,
    required this.onTap,
  });

  @override
  State<_ToolbarItem> createState() => _ToolbarItemState();
}

class _ToolbarItemState extends State<_ToolbarItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8), // Further increased spacing for polish
      child: FocusableActionDetector(
        onFocusChange: (val) => setState(() => _isFocused = val),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: widget.child != null ? EdgeInsets.zero : const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: widget.child != null ? BoxShape.rectangle : BoxShape.circle,
              color: _isFocused ? const Color(0xAA4A3D6A) : Colors.transparent,
              borderRadius: widget.child != null ? BorderRadius.circular(30) : null,
              boxShadow: _isFocused ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                )
              ] : [],
            ),
            child: widget.child ?? Icon(
              widget.icon,
              color: _isFocused ? Colors.white : Colors.white70,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
