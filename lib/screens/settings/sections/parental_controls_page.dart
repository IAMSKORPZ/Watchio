import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../widgets/watchio_settings_scaffold.dart';

class ParentalControlsPage extends StatelessWidget {
  const ParentalControlsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchioSettingsScaffold(
      title: 'PARENTAL CONTROLS',
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
                    title: 'Enable PIN',
                    subtitle: 'Require PIN to access locked content',
                    initialValue: false,
                  ),
                  _SettingsActionTile(
                    title: 'Change PIN',
                    subtitle: 'Set a new 4-digit parental control PIN',
                    onTap: () {},
                  ),
                  _SettingsActionTile(
                    title: 'Lock Categories',
                    subtitle: 'Choose which categories require a PIN',
                    onTap: () {},
                  ),
                  _SettingsActionTile(
                    title: 'Lock Settings',
                    subtitle: 'Prevent unauthorized settings changes',
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

class _SettingsActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLast;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
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
          onTap: onTap,
        ),
        if (!isLast) const Divider(color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}
