import 'dart:async';

import 'package:another_iptv_player/models/api_configuration_model.dart';
import 'package:another_iptv_player/repositories/iptv_repository.dart';
import 'package:another_iptv_player/services/app_state.dart';
import 'package:another_iptv_player/services/epg_source_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/xtream_code_home_controller.dart';
import '../../models/playlist_model.dart';
import '../../models/content_type.dart';
import '../../shared/widgets/app_shell.dart';
import '../home/bingie_dashboard_home.dart';
import '../watch_history_screen.dart';
import '../announcements/announcements_screen.dart';
import '../../l10n/localization_extension.dart';
import '../search_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../movies/xtream_movies_screen.dart';
import '../series/xtream_series_screen.dart';
import '../live_stream/xtream_live_screen.dart';
import '../sports/sports_hub_screen.dart';
import '../settings/watchio_settings_screen.dart';
import '../trakt/trakt_screen.dart';

class XtreamCodeHomeScreen extends StatefulWidget {
  final Playlist playlist;

  const XtreamCodeHomeScreen({super.key, required this.playlist});

  @override
  State<XtreamCodeHomeScreen> createState() => _XtreamCodeHomeScreenState();
}

class _XtreamCodeHomeScreenState extends State<XtreamCodeHomeScreen> {
  late XtreamCodeHomeController _controller;
  String _version = '0.0.1';

  @override
  void initState() {
    super.initState();
    _initializeController();
    _loadVersion();
  }

  void _initializeController() {
    final repository = IptvRepository(
      ApiConfig(
        baseUrl: widget.playlist.url ?? '',
        username: widget.playlist.username ?? '',
        password: widget.playlist.password ?? '',
      ),
      widget.playlist.id,
    );
    AppState.xtreamCodeRepository = repository;
    AppState.currentPlaylist = widget.playlist;
    unawaited(EpgSourceService.refreshOnStartup(widget.playlist));
    _controller = XtreamCodeHomeController(false);
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAnnouncements() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WatchioAnnouncementsScreen()),
    );
  }

  void _showSportsHub() {
    // We will create this screen shortly
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SportsHubScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<XtreamCodeHomeController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final userInfo = controller.userInfo?.userInfo;

          final navItems = [
            (icon: Icons.home_rounded, label: context.loc.home),
            (icon: Icons.history_rounded, label: context.loc.history),
            (icon: Icons.live_tv_rounded, label: context.loc.live_streams),
            (icon: Icons.movie_rounded, label: context.loc.movies),
            (icon: Icons.tv_rounded, label: context.loc.series_plural),
            (icon: Icons.settings_rounded, label: context.loc.settings),
          ];

          return AppShell(
            currentIndex: controller.currentIndex,
            onIndexChanged: controller.onNavigationTap,
            navItems: navItems,
            onSearchTap: () => _navigateToSearch(ContentType.liveStream),
            onRefreshTap: () => controller.refreshAllData(context),
            onSettingsTap: () => controller.onNavigationTap(5),
            pages: [
              BingieDashboardHome(
                onLiveTv: () => controller.onNavigationTap(2),
                onMovies: () => controller.onNavigationTap(3),
                onSeries: () => controller.onNavigationTap(4),
                onAnnouncements: _showAnnouncements,
                onUpdate: () => controller.refreshAllData(context),
                onSettings: () => controller.onNavigationTap(5),
                onSearch: () => _navigateToSearch(ContentType.liveStream),
                onSports: _showSportsHub,
                onProfile: () => controller.onNavigationTap(5),
                onTrakt: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TraktScreen()),
                ),
                username: userInfo?.username ?? 'Guest',
                expiryDate: userInfo?.expDate ?? 'N/A',
                version: _version,
              ),
              WatchHistoryScreen(playlistId: widget.playlist.id),
              XtreamLiveScreen(playlist: widget.playlist),
              XtreamMoviesScreen(),
              XtreamSeriesScreen(),
              const WatchioSettingsScreen(),
            ],
          );
        },
      ),
    );
  }

  void _navigateToSearch(ContentType contentType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(contentType: contentType),
      ),
    );
  }
}
