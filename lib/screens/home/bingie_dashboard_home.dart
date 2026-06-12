import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/config_service.dart';
import 'widgets/home_tile.dart';
import 'widgets/home_header.dart';
import 'widgets/home_footer.dart';
import 'widgets/home_bottom_button.dart';
import 'home_theme.dart';

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
          final double verticalPadding = height * 0.01;
          final double gap = width * 0.012;

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
                    const Color(0xFF050812).withValues(alpha: 0.4),
                    const Color(0xFF050812).withValues(alpha: 0.8),
                    const Color(0xFF050812),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  children: [
                    HomeHeader(
                      onSearch: widget.onSearch,
                      onProfile: widget.onProfile,
                      onAbout: widget.onAbout,
                    ),
                    
                    const Spacer(flex: 1),
                    
                    Expanded(
                      flex: 12,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 30,
                            child: HomeTile(
                              title: 'LIVE TV',
                              subtitle: 'Watch Live TV Channels',
                              icon: Icons.live_tv_rounded,
                              colors: HomeTheme.liveTvColors,
                              onTap: widget.onLiveTv,
                              large: true,
                              autofocus: true,
                            ),
                          ),
                          
                          SizedBox(width: gap),
                          
                          Expanded(
                            flex: 70,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 70,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: HomeTile(
                                          title: 'MOVIES',
                                          subtitle: 'Browse and watch movies',
                                          icon: Icons.play_circle_filled_rounded,
                                          colors: HomeTheme.moviesColors,
                                          onTap: widget.onMovies,
                                        ),
                                      ),
                                      SizedBox(width: gap),
                                      Expanded(
                                        child: HomeTile(
                                          title: 'SERIES',
                                          subtitle: 'Discover and binge series',
                                          icon: Icons.movie_creation_rounded,
                                          colors: HomeTheme.seriesColors,
                                          onTap: widget.onSeries,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(height: gap),
                                
                                Expanded(
                                  flex: 30,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: HomeBottomButton(
                                          label: 'ANNOUNCEMENTS',
                                          icon: Icons.campaign_rounded,
                                          color: HomeTheme.iconAnnouncements,
                                          onTap: widget.onAnnouncements,
                                        ),
                                      ),
                                      SizedBox(width: gap),
                                      Expanded(
                                        child: HomeBottomButton(
                                          label: 'UPDATE',
                                          icon: Icons.sync_rounded,
                                          color: HomeTheme.iconUpdate,
                                          onTap: widget.onUpdate,
                                        ),
                                      ),
                                      SizedBox(width: gap),
                                      Expanded(
                                        child: HomeBottomButton(
                                          label: 'SETTINGS',
                                          icon: Icons.settings_rounded,
                                          color: HomeTheme.iconSettings,
                                          onTap: widget.onSettings,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(flex: 1),
                    
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
