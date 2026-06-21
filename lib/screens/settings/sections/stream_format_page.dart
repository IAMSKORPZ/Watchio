import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../widgets/watchio_settings_scaffold.dart';

class StreamFormatPage extends StatefulWidget {
  const StreamFormatPage({super.key});

  @override
  State<StreamFormatPage> createState() => _StreamFormatPageState();
}

class _StreamFormatPageState extends State<StreamFormatPage> {
  String _format = 'auto';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _format = prefs.getString('stream_format') ?? 'auto');
    }
  }

  Future<void> _select(String value) async {
    setState(() => _format = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stream_format', value);
  }

  @override
  Widget build(BuildContext context) {
    return WatchioSettingsScaffold(
      title: 'STREAM FORMAT',
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  _FormatSelectionTile(
                    title: 'Auto',
                    subtitle: 'Let Watchio choose the best format',
                    isSelected: _format == 'auto',
                    onTap: () => _select('auto'),
                  ),
                  _FormatSelectionTile(
                    title: 'TS',
                    subtitle: 'Transport Stream (Recommended for Live TV)',
                    isSelected: _format == 'ts',
                    onTap: () => _select('ts'),
                  ),
                  _FormatSelectionTile(
                    title: 'HLS',
                    subtitle: 'HTTP Live Streaming',
                    isSelected: _format == 'hls',
                    onTap: () => _select('hls'),
                  ),
                  _FormatSelectionTile(
                    title: 'MPEG-TS',
                    subtitle: 'Legacy MPEG Transport Stream',
                    isSelected: _format == 'mpegts',
                    onTap: () => _select('mpegts'),
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
  final VoidCallback onTap;

  const _FormatSelectionTile({
    required this.title,
    required this.subtitle,
    this.isSelected = false,
    this.isLast = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
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
          onTap: onTap,
        ),
        if (!isLast)
          const Divider(color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}
