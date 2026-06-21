import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../widgets/watchio_settings_scaffold.dart';

class ProviderManagementPage extends StatelessWidget {
  const ProviderManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchioSettingsScaffold(
      title: 'PROVIDER MANAGEMENT',
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlassPanel(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _ProviderTile(
                        name: 'Watchio Premium',
                        url: 'http://premium.watchio.tv',
                        isActive: true,
                      ),
                      Divider(color: Colors.white10, height: 48),
                      _ProviderTile(
                        name: 'Backup Provider',
                        url: 'http://backup.stream.io',
                        isActive: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('ADD NEW PROVIDER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC12CFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: const Color(0xFFC12CFF).withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final String name;
  final String url;
  final bool isActive;

  const _ProviderTile({
    required this.name,
    required this.url,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00B7FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00B7FF).withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.dns_rounded, color: Color(0xFF00B7FF), size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                url,
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              'ACTIVE',
              style: GoogleFonts.outfit(
                color: Colors.greenAccent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white38, size: 22),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
          onPressed: () {},
        ),
      ],
    );
  }
}
