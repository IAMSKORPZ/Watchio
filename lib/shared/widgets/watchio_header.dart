import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WatchioHeader extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback? onMenu;
  final VoidCallback? onSort;
  final VoidCallback? onRefresh;
  final VoidCallback? onSettings;

  const WatchioHeader({
    super.key,
    required this.onBack,
    required this.onSearch,
    this.onMenu,
    this.onSort,
    this.onRefresh,
    this.onSettings,
  });

  @override
  State<WatchioHeader> createState() => _WatchioHeaderState();
}

class _WatchioHeaderState extends State<WatchioHeader> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          // LEFT: Back + Logo
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: widget.onBack,
              ),
              const SizedBox(width: 16),
              Image.asset(
                'assets/images/App_Logo.png',
                height: 68,
                fit: BoxFit.contain,
              ),
            ],
          ),
          
          const Spacer(),
          
          // CENTER: Time & Date
          Column(
            children: [
              Text(
                DateFormat('hh:mm a').format(_now),
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 20, 
                  fontWeight: FontWeight.w900
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy').format(_now),
                style: const TextStyle(
                  color: Color(0xFFC12CFF), 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // RIGHT: Search + More
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.search_rounded, 
                onTap: widget.onSearch
              ),
              const SizedBox(width: 12),
              _buildMenu(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.white.withValues(alpha: 0.1),
      ),
      child: PopupMenuButton<String>(
        icon: const _HeaderIconContainer(icon: Icons.more_vert_rounded),
        offset: const Offset(0, 50),
        color: const Color(0xFF1A1D29),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
        onSelected: (value) {
          switch (value) {
            case 'sort': widget.onSort?.call(); break;
            case 'refresh': widget.onRefresh?.call(); break;
            case 'settings': (widget.onSettings ?? widget.onMenu)?.call(); break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'sort',
            child: Row(children: [Icon(Icons.sort_rounded, color: Colors.white70, size: 20), SizedBox(width: 12), Text('Sort Options', style: TextStyle(color: Colors.white))]),
          ),
          const PopupMenuItem(
            value: 'refresh',
            child: Row(children: [Icon(Icons.refresh_rounded, color: Colors.white70, size: 20), SizedBox(width: 12), Text('Refresh Content', style: TextStyle(color: Colors.white))]),
          ),
          const PopupMenuItem(
            value: 'settings',
            child: Row(children: [Icon(Icons.settings_rounded, color: Colors.white70, size: 20), SizedBox(width: 12), Text('Settings', style: TextStyle(color: Colors.white))]),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconContainer extends StatelessWidget {
  final IconData icon;

  const _HeaderIconContainer({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Icon(
        icon, 
        color: Colors.white70,
        size: 22
      ),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _isFocused = false;
  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (v) => setState(() => _isFocused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused ? const Color(0xFFC12CFF) : Colors.white10
            ),
          ),
          child: Icon(
            widget.icon, 
            color: _isFocused ? Colors.white : Colors.white70, 
            size: 22
          ),
        ),
      ),
    );
  }
}
