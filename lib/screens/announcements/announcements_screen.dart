import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement_v2_model.dart';
import '../../services/announcement_service.dart';
import '../../services/config_service.dart';
import '../home/widgets/home_header.dart';
import '../home/home_theme.dart';
import '../../shared/widgets/glass_panel.dart';
import '../../shared/widgets/app_card.dart';

class WatchioAnnouncementsScreen extends StatelessWidget {
  const WatchioAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>().config;
    final announcementService = context.watch<AnnouncementService>();
    final homeBg = config.backgrounds.home;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: HomeTheme.background,
          image: DecorationImage(
            image: homeBg.isNotEmpty
                ? NetworkImage(homeBg)
                : const AssetImage('assets/images/background.png') as ImageProvider,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: HomeHeader(
                  onSearch: () {},
                  onProfile: () {},
                  onAbout: () {},
                  onSports: () {
                    // Navigate to Sports Hub if needed
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              const Text(
                'ANNOUNCEMENTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Announcements List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: announcementService.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : announcementService.announcements.isEmpty
                          ? const Center(
                              child: Text(
                                'No announcements available',
                                style: TextStyle(color: Colors.white70, fontSize: 18),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: announcementService.announcements.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = announcementService.announcements[index];
                                return _AnnouncementListCard(
                                  announcement: item,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WatchioAnnouncementDetailsScreen(announcement: item),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ),
              
              // Back Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: HeaderButton(
                    icon: Icons.arrow_back,
                    label: 'BACK TO DASHBOARD',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementListCard extends StatefulWidget {
  final AnnouncementV2Model announcement;
  final VoidCallback onTap;

  const _AnnouncementListCard({
    required this.announcement,
    required this.onTap,
  });

  @override
  State<_AnnouncementListCard> createState() => _AnnouncementListCardState();
}

class _AnnouncementListCardState extends State<_AnnouncementListCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (val) => setState(() => _isFocused = val),
      child: AppCard(
        onTap: widget.onTap,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: Colors.white70, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.announcement.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.announcement.date,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class WatchioAnnouncementDetailsScreen extends StatelessWidget {
  final AnnouncementV2Model announcement;

  const WatchioAnnouncementDetailsScreen({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>().config;
    final homeBg = config.backgrounds.home;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: HomeTheme.background,
          image: DecorationImage(
            image: homeBg.isNotEmpty
                ? NetworkImage(homeBg)
                : const AssetImage('assets/images/background.png') as ImageProvider,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: HomeHeader(
                  onSearch: () {},
                  onProfile: () {},
                  onAbout: () {},
                  onSports: () {
                    // Navigate to Sports Hub if needed
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Content Area
              Expanded(
                child: Center(
                  child: AppCard(
                    width: MediaQuery.of(context).size.width * 0.7,
                    padding: const EdgeInsets.all(40),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            announcement.title.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: Colors.white10, thickness: 1),
                          ),
                          Text(
                            announcement.message,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              announcement.date,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Back Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: HeaderButton(
                    icon: Icons.arrow_back,
                    label: 'BACK TO LIST',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
