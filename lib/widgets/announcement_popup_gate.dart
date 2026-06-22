import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/announcement_v2_model.dart';
import '../services/announcement_service.dart';

class AnnouncementPopupGate extends StatefulWidget {
  const AnnouncementPopupGate({super.key, required this.child});

  final Widget child;

  @override
  State<AnnouncementPopupGate> createState() => _AnnouncementPopupGateState();
}

class _AnnouncementPopupGateState extends State<AnnouncementPopupGate> {
  bool _checking = false;
  bool _showing = false;
  int _lastCheckedNewestId = -1;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AnnouncementService>();
    final newestId = service.announcements.isEmpty
        ? 0
        : service.announcements.first.id;
    if (!service.isLoading &&
        !_checking &&
        !_showing &&
        newestId != _lastCheckedNewestId) {
      _lastCheckedNewestId = newestId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _check(service));
    }
    return widget.child;
  }

  Future<void> _check(AnnouncementService service) async {
    if (!mounted || _checking || _showing) return;
    _checking = true;
    final announcement = await service.latestUndismissed();
    _checking = false;
    if (!mounted || announcement == null) return;
    _showing = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: _AnnouncementDialog(
          announcement: announcement,
          onDismiss: () async {
            await service.dismiss(announcement);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
        ),
      ),
    );
    _showing = false;
  }
}

class _AnnouncementDialog extends StatelessWidget {
  const _AnnouncementDialog({
    required this.announcement,
    required this.onDismiss,
  });

  final AnnouncementV2Model announcement;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111525),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      title: Row(
        children: [
          Icon(
            Icons.campaign_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(announcement.title)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                announcement.date,
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              Text(
                announcement.message,
                style: const TextStyle(fontSize: 17, height: 1.4),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          autofocus: true,
          onPressed: onDismiss,
          child: const Text('DISMISS'),
        ),
      ],
    );
  }
}
