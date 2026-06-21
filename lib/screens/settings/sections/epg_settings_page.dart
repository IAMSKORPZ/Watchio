import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/app_state.dart';
import '../../../services/epg_source_service.dart';
import '../../../services/epg_storage_service.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../widgets/watchio_settings_scaffold.dart';

class EpgSettingsPage extends StatefulWidget {
  const EpgSettingsPage({super.key});

  @override
  State<EpgSettingsPage> createState() => _EpgSettingsPageState();
}

class _EpgSettingsPageState extends State<EpgSettingsPage> {
  bool _autoRefresh = true;
  bool _working = false;
  String _interval = '24';
  String _status = 'Ready to scan provider and built-in EPG sources';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _autoRefresh = prefs.getBool('epg_auto_refresh') ?? true;
      _interval = prefs.getString('epg_refresh_interval') ?? '24';
    });
  }

  Future<void> _updateEpg() async {
    final playlist = AppState.currentPlaylist;
    if (playlist == null || _working) return;
    setState(() => _working = true);
    try {
      final source = await EpgSourceService().discoverAndImport(
        playlist: playlist,
        onStatus: (status) {
          if (mounted) setState(() => _status = status);
        },
      );
      final storage = EpgStorageService();
      final channels = await storage.getChannelCount(playlist.id);
      final programmes = await storage.getProgramCount(playlist.id);
      if (mounted) {
        setState(
          () => _status =
              '${source.label}: $channels channels, $programmes programmes imported',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _status = 'EPG update failed: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _setAutoRefresh(bool value) async {
    setState(() => _autoRefresh = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('epg_auto_refresh', value);
  }

  Future<void> _setInterval(String? value) async {
    if (value == null) return;
    setState(() => _interval = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('epg_refresh_interval', value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return WatchioSettingsScaffold(
      title: 'EPG SETTINGS',
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 8, 40, 8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -3),
                    leading: _working
                        ? SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              color: accent,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            Icons.travel_explore_rounded,
                            color: accent,
                            size: 24,
                          ),
                    title: Text('Scan & Update EPG', style: _titleStyle),
                    subtitle: Text(_status, style: _subtitleStyle),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white24,
                      size: 18,
                    ),
                    onTap: _working ? null : _updateEpg,
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -3),
                    title: Text('Auto Refresh EPG', style: _titleStyle),
                    subtitle: Text(
                      'Automatically update guide in background',
                      style: _subtitleStyle,
                    ),
                    value: _autoRefresh,
                    onChanged: _setAutoRefresh,
                    activeThumbColor: accent,
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -3),
                    title: Text('Source Priority', style: _titleStyle),
                    subtitle: Text(
                      'Provider → playlist XMLTV → built-in regional guides',
                      style: _subtitleStyle,
                    ),
                    trailing: Text(
                      'Automatic',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -3),
                    title: Text('Refresh Interval', style: _titleStyle),
                    subtitle: Text(
                      'How often automatic updates run',
                      style: _subtitleStyle,
                    ),
                    trailing: DropdownButton<String>(
                      value: _interval,
                      dropdownColor: const Color(0xFF1A1D29),
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: '6',
                          child: Text('Every 6 Hours'),
                        ),
                        DropdownMenuItem(
                          value: '12',
                          child: Text('Every 12 Hours'),
                        ),
                        DropdownMenuItem(
                          value: '24',
                          child: Text('Every 24 Hours'),
                        ),
                      ],
                      onChanged: _setInterval,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static final _titleStyle = GoogleFonts.outfit(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 13,
  );
  static final _subtitleStyle = GoogleFonts.outfit(
    color: Colors.white38,
    fontSize: 10,
  );
}
