import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/config_service.dart';
import 'widgets/home_tile.dart';
import 'widgets/home_header.dart';
import 'widgets/home_footer.dart';
import 'widgets/home_bottom_button.dart';

class BingieDashboardHome extends StatefulWidget {
  final VoidCallback onLiveTv;
  final VoidCallback onMovies;
  final VoidCallback onSeries;
  final VoidCallback onAnnouncements;
  final VoidCallback onUpdate;
  final VoidCallback onSettings;
  final VoidCallback onSearch;
  final VoidCallback onProfile;
  final VoidCallback onAbout;
  final String username;
  final String expiryDate;
  final String version;

  const BingieDashboardHome({
    super.key,
    required this.onLiveTv,
    required this.onMovies,
    required this.onSeries,
    required this.onAnnouncements,
    required this.onUpdate,
    required this.onSettings,
    required this.onSearch,
    required this.onProfile,
    required this.onAbout,
    required this.username,
    required this.expiryDate,
    required this.version,
  });

  @override
  State<BingieDashboardHome> createState() => _BingieDashboardHomeState();
}

class _BingieDashboardHomeState extends State<BingieDashboardHome> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reinforce fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final config = context.watch<ConfigService>().config;
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;
          
          final double horizontalPadding = width * 0.05;
          final double verticalPadding = height * 0.04; // Increased vertical padding for more breathing room
          final double gap = width * 0.015;

          final homeBg = config.backgrounds.home;

          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF050812),
              image: DecorationImage(
                image: (homeBg.isNotEmpty)
                    ? NetworkImage(homeBg)
                    : const AssetImage('assets/images/background.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF050812).withValues(alpha: 0.2),
                    const Color(0xFF050812).withValues(alpha: 0.6),
                    const Color(0xFF050812).withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  children: [
                    // TOP HEADER
                    HomeHeader(
                      onSearch: widget.onSearch,
                      onProfile: widget.onProfile,
                      onAbout: widget.onAbout,
                      onAnnouncements: widget.onAnnouncements,
                    ),
                    
                    const Spacer(flex: 2),
                    
                    // MAIN CONTENT - 3 CARDS
                    Expanded(
                      flex: 14, // Increased height by approx 15% to feel more premium
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: HomeTile(
                              title: 'LIVE TV',
                              subtitle: 'Watch Live TV Channels',
                              icon: Icons.live_tv_rounded, // IPTV-style icon
                              accentColor: const Color(0xFFC12CFF), // Purple
                              onTap: widget.onLiveTv,
                              autofocus: true,
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: HomeTile(
                              title: 'MOVIES',
                              subtitle: 'Browse a wide selection',
                              icon: Icons.play_arrow_rounded,
                              accentColor: Colors.orange,
                              onTap: widget.onMovies,
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: HomeTile(
                              title: 'SERIES',
                              subtitle: 'Discover and binge-watch',
                              icon: Icons.movie_rounded,
                              accentColor: const Color(0xFF00B7FF), // Blue/Cyan
                              onTap: widget.onSeries,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8), // Reduced gap to move Action Row upward
                    
                    // SECONDARY ACTION ROW
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Expanded(
                            child: HomeBottomButton(
                              label: 'LIVE + EPG',
                              icon: Icons.list_alt_rounded,
                              onTap: widget.onLiveTv, // Assuming Live TV with EPG is handled by same callback or similar
                              accentColor: const Color(0xFFC12CFF),
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: HomeBottomButton(
                              label: 'REFRESH',
                              icon: Icons.refresh_rounded,
                              onTap: widget.onUpdate,
                              accentColor: Colors.white,
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            child: HomeBottomButton(
                              label: 'SETTINGS',
                              icon: Icons.settings_rounded,
                              onTap: widget.onSettings,
                              accentColor: const Color(0xFF00B7FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(flex: 2),
                    
                    // BOTTOM STATUS BAR
                    HomeFooter(
                      username: widget.username,
                      expiryDate: widget.expiryDate,
                      version: widget.version,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
