import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../widgets/watchio_settings_scaffold.dart';

class EpgSettingsPage extends StatelessWidget {
  const EpgSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchioSettingsScaffold(
      title: 'EPG SETTINGS',
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
                    title: 'Update EPG',
                    subtitle: 'Manually refresh programme guide now',
                    icon: Icons.refresh_rounded,
                    onTap: () {},
                  ),
                  const _SettingsToggleTile(
                    title: 'Auto Refresh EPG',
                    subtitle: 'Automatically update guide in background',
                    initialValue: true,
                  ),
                  const _SettingsDropdownTile(
                    title: 'EPG Source',
                    subtitle: 'Select source for guide data',
                    value: 'Provider Default',
                  ),
                  const _SettingsDropdownTile(
                    title: 'Time Offset',
                    subtitle: 'Adjust EPG time if it doesn\'t match',
                    value: '0 Hours',
                  ),
                  const _SettingsDropdownTile(
                    title: 'Refresh Interval',
                    subtitle: 'How often to check for updates',
                    value: 'Every 24 Hours',
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

class _SettingsToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool initialValue;

  const _SettingsToggleTile({
    required this.title,
    required this.subtitle,
    required this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Text(
            title,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
          ),
          trailing: Switch(
            value: initialValue,
            onChanged: (v) {},
            activeThumbColor: const Color(0xFFC12CFF),
          ),
        ),
        const Divider(color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _SettingsDropdownTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final bool isLast;

  const _SettingsDropdownTile({
    required this.title,
    required this.subtitle,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Text(
            title,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(color: const Color(0xFF00B7FF), fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, color: Colors.white38),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
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
              color: const Color(0xFFC12CFF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC12CFF).withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: const Color(0xFFC12CFF), size: 24),
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
        const Divider(color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}
