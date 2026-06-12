import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:another_iptv_player/l10n/localization_extension.dart';
import 'package:another_iptv_player/models/playlist_model.dart';
import 'package:another_iptv_player/controllers/xtream_code_home_controller.dart';
import 'package:another_iptv_player/screens/settings/announcement_center_screen.dart';
import 'package:another_iptv_player/widgets/tv_focusable.dart';

class XtreamCodeDashboard extends StatefulWidget {
  final Playlist playlist;
  final XtreamCodeHomeController controller;
  final VoidCallback? onSearchTap;

  const XtreamCodeDashboard({
    super.key,
    required this.playlist,
    required this.controller,
    this.onSearchTap,
  });

  @override
  State<XtreamCodeDashboard> createState() => _XtreamCodeDashboardState();
}

class _XtreamCodeDashboardState extends State<XtreamCodeDashboard> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E21), Color(0xFF1D1E33)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isSmallHeight = constraints.maxHeight < 450;
            
            return SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, isSmallHeight),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 30.0,
                        vertical: isSmallHeight ? 5 : 10,
                      ),
                      child: _buildMainGrid(context, isSmallHeight),
                    ),
                  ),
                  _buildFooter(context, isSmallHeight),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 30.0,
        vertical: isSmallHeight ? 10.0 : 20.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo Section
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png', height: isSmallHeight ? 35 : 50, 
                  errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.tv, color: Colors.blue, size: isSmallHeight ? 30 : 40)),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('WATCHIO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallHeight ? 18 : 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('PRO',
                        style: TextStyle(
                          color: Colors.blue.shade400,
                          fontSize: isSmallHeight ? 10 : 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Time/Date Section
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('hh:mm a').format(_now),
                  style: TextStyle(color: Colors.white, fontSize: isSmallHeight ? 16 : 20, fontWeight: FontWeight.w600)),
                if (!isSmallHeight)
                  Text(DateFormat('MMM d, yyyy').format(_now),
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),

          // Actions Section
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHeaderAction(Icons.search, context.loc.search, () => widget.onSearchTap?.call()),
                const SizedBox(width: 10),
                _buildHeaderAction(Icons.refresh, 'Update', () => widget.controller.refreshAllData(context)),
                const SizedBox(width: 10),
                _buildHeaderAction(Icons.settings_outlined, '', () => widget.controller.onNavigationTap(5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, String label, VoidCallback onTap) {
    return TvFocusable(
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 10 : 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainGrid(BuildContext context, bool isSmallHeight) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: _buildMainTile(
                  title: 'LIVE TV',
                  subtitle: 'Watch Live TV Channels',
                  icon: Icons.live_tv_rounded,
                  gradient: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  badge: 'LIVE',
                  isSmallHeight: isSmallHeight,
                  onTap: () => widget.controller.onNavigationTap(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMainTile(
                  title: 'MOVIES',
                  subtitle: 'Explore Movies',
                  icon: Icons.movie_outlined,
                  gradient: const [Color(0xFF0F766E), Color(0xFF2563EB)],
                  isSmallHeight: isSmallHeight,
                  onTap: () => widget.controller.onNavigationTap(3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMainTile(
                  title: 'SERIES',
                  subtitle: 'Explore Series',
                  icon: Icons.video_library_outlined,
                  gradient: const [Color(0xFF581C87), Color(0xFFBE185D)],
                  isSmallHeight: isSmallHeight,
                  onTap: () => widget.controller.onNavigationTap(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(
                child: _buildSmallTile(
                  title: 'ANNOUNCEMENTS',
                  subtitle: 'Latest Updates',
                  icon: Icons.campaign_outlined,
                  iconColor: Colors.purpleAccent,
                  isSmallHeight: isSmallHeight,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AnnouncementCenterScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSmallTile(
                  title: 'MULTI SCREEN',
                  subtitle: 'Watch on Multiple Screens',
                  icon: Icons.screenshot_monitor_outlined,
                  iconColor: Colors.lightBlueAccent,
                  isSmallHeight: isSmallHeight,
                  onTap: () => widget.controller.onNavigationTap(1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSmallTile(
                  title: 'SETTINGS',
                  subtitle: 'App Preferences',
                  icon: Icons.settings,
                  iconColor: Colors.orange,
                  isSmallHeight: isSmallHeight,
                  onTap: () => widget.controller.onNavigationTap(5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    String? badge,
    required bool isSmallHeight,
    required VoidCallback onTap,
  }) {
    return TvFocusable(
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: gradient.first.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(
          children: [
            if (badge != null && !isSmallHeight)
              Positioned(
                top: 15, left: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, color: Colors.white, size: 6),
                      const SizedBox(width: 6),
                      Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: isSmallHeight ? 50 : 70),
                  SizedBox(height: isSmallHeight ? 8 : 15),
                  Text(title, style: TextStyle(color: Colors.white, fontSize: isSmallHeight ? 20 : 30, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  if (!isSmallHeight)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 15, right: 15,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Color iconColor = Colors.blue,
    required bool isSmallHeight,
    required VoidCallback onTap,
  }) {
    return TvFocusable(
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: TextStyle(color: Colors.white, fontSize: isSmallHeight ? 12 : 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && !isSmallHeight)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(icon, color: iconColor, size: isSmallHeight ? 24 : 35),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isSmallHeight) {
    final userInfo = widget.controller.userInfo;
    String expiration = 'Lifetime';
    if (userInfo?.userInfo.expDate != null) {
      try {
        final date = DateTime.fromMillisecondsSinceEpoch(int.parse(userInfo!.userInfo.expDate) * 1000);
        expiration = DateFormat('MMM d, yyyy').format(date);
      } catch (_) {}
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: isSmallHeight ? 8 : 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, color: Colors.purpleAccent, size: 16),
                const SizedBox(width: 8),
                Text('Exp: $expiration', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (!isSmallHeight)
            const Expanded(
              child: Text('By using this app, you agree to the Terms of Service.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 10)),
            )
          else
            const Spacer(),
          Text('Logged in: ${userInfo?.userInfo.username ?? "Guest"}',
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
