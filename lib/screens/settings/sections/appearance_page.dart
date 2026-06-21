import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../widgets/watchio_settings_scaffold.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchioSettingsScaffold(
      title: 'APPEARANCE',
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
                  _SettingsDropdownTile(
                    title: 'Theme',
                    subtitle: 'Select application visual style',
                    value: 'Glassmorphism Dark',
                    onTap: () {},
                  ),
                  _SettingsDropdownTile(
                    title: 'Accent Color',
                    subtitle: 'Primary color for highlights and glow',
                    value: 'Vivid Purple',
                    onTap: () {},
                  ),
                  _SettingsDropdownTile(
                    title: 'Background Style',
                    subtitle: 'Choose between dynamic or static background',
                    value: 'Dynamic Mesh',
                    onTap: () {},
                  ),
                  _SettingsDropdownTile(
                    title: 'Tile Style',
                    subtitle: 'Adjust card corners and glass intensity',
                    value: 'Rounded Glass',
                    onTap: () {},
                  ),
                  const _SettingsToggleTile(
                    title: 'Animations',
                    subtitle: 'Enable smooth transitions and focus effects',
                    initialValue: true,
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
  final bool isLast;

  const _SettingsToggleTile({
    required this.title,
    required this.subtitle,
    required this.initialValue,
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
          trailing: Switch(
            value: initialValue,
            onChanged: (v) {},
            activeThumbColor: const Color(0xFFC12CFF),
          ),
        ),
        if (!isLast) const Divider(color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _SettingsDropdownTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;

  const _SettingsDropdownTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
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
          onTap: onTap,
        ),
        const Divider(color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}
