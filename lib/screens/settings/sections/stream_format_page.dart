import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../widgets/watchio_settings_scaffold.dart';

class StreamFormatPage extends StatelessWidget {
  const StreamFormatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchioSettingsScaffold(
      title: 'STREAM FORMAT',
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const GlassPanel(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  _FormatSelectionTile(
                    title: 'Auto',
                    subtitle: 'Let Watchio choose the best format',
                    isSelected: true,
                  ),
                  _FormatSelectionTile(
                    title: 'TS',
                    subtitle: 'Transport Stream (Recommended for Live TV)',
                  ),
                  _FormatSelectionTile(
                    title: 'HLS',
                    subtitle: 'HTTP Live Streaming',
                  ),
                  _FormatSelectionTile(
                    title: 'MPEG-TS',
                    subtitle: 'Legacy MPEG Transport Stream',
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

class _FormatSelectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isLast;

  const _FormatSelectionTile({
    required this.title,
    required this.subtitle,
    this.isSelected = false,
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
          trailing: isSelected
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC12CFF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFC12CFF),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                )
              : null,
          onTap: () {},
        ),
        if (!isLast) const Divider(color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}
