import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../widgets/watchio_settings_scaffold.dart';

class BackupRestorePage extends StatelessWidget {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchioSettingsScaffold(
      title: 'BACKUP & RESTORE',
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: GlassPanel(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _SettingsActionTile(
                    title: 'Export Settings',
                    subtitle: 'Save your configuration to a file',
                    icon: Icons.file_upload_rounded,
                    onTap: () {},
                  ),
                  _SettingsActionTile(
                    title: 'Import Settings',
                    subtitle: 'Load configuration from a backup file',
                    icon: Icons.file_download_rounded,
                    onTap: () {},
                  ),
                  _SettingsActionTile(
                    title: 'Export Profiles',
                    subtitle: 'Backup your playlist profiles and logins',
                    icon: Icons.people_alt_rounded,
                    onTap: () {},
                  ),
                  _SettingsActionTile(
                    title: 'Restore Backup',
                    subtitle: 'Complete system restoration from file',
                    icon: Icons.settings_backup_restore_rounded,
                    onTap: () {},
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00B7FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00B7FF).withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: const Color(0xFF00B7FF), size: 24),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 18),
          onTap: onTap,
        ),
        if (!isLast) const Divider(color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}
