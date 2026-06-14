import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:another_iptv_player/controllers/branding_controller.dart';
import 'package:another_iptv_player/shared/widgets/app_card.dart';

class AnnouncementCenterScreen extends StatelessWidget {
  const AnnouncementCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BrandingController>();
    final announcements = controller.activeAnnouncements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: announcements.isEmpty
          ? const Center(child: Text('No active announcements.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = announcements[index];
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${item.priority}')),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${item.body}\nCreated: ${_format(item.createdAt)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  String _format(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
