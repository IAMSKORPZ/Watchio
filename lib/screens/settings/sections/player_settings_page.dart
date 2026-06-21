import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../widgets/watchio_settings_scaffold.dart';

class PlayerSettingsPage extends StatelessWidget {
  const PlayerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchioSettingsScaffold(
      title: 'PLAYER SETTINGS',
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
                  const _SettingsToggleTile(
                    title: 'Auto Play Preview',
                    subtitle: 'Start playback automatically when a channel is focused',
                    initialValue: true,
                  ),
                  const _SettingsToggleTile(
                    title: 'Hardware Decoding',
                    subtitle: 'Use GPU for video decoding (Recommended)',
                    initialValue: true,
                  ),
                  const _SettingsToggleTile(
                    title: 'Software Decoding',
                    subtitle: 'Fallback for incompatible video formats',
                    initialValue: false,
                  ),
                  const _SettingsDropdownTile(
                    title: 'Buffer Size',
                    subtitle: 'Adjust for slower network connections',
                    value: 'Auto (Default)',
                  ),
                  const _SettingsDropdownTile(
                    title: 'Aspect Ratio',
                    subtitle: 'Set default video display ratio',
                    value: 'Fit to Screen',
                  ),
                  const _SettingsToggleTile(
                    title: 'Auto Fullscreen',
                    subtitle: 'Switch to fullscreen on channel selection',
                    initialValue: false,
                  ),
                  _SettingsActionTile(
                    title: 'Subtitle Settings',
                    subtitle: 'Configure default language and appearance',
                  ),
                  _SettingsActionTile(
                    title: 'Audio Settings',
                    subtitle: 'Manage audio tracks and sync',
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

  const _SettingsDropdownTile({
    required this.title,
    required this.subtitle,
    required this.value,
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
                const SizedBox(width: 12),
                const Icon(Icons.arrow_drop_down, color: Colors.white38),
              ],
            ),
          ),
        ),
        const Divider(color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLast;

  const _SettingsActionTile({
    required this.title,
    required this.subtitle,
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
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 18),
          onTap: () {},
        ),
        if (!isLast) const Divider(color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}
