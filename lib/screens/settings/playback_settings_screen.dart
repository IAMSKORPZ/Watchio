import 'package:flutter/material.dart';
import '../../models/player_engine.dart';
import '../../repositories/user_preferences.dart';
import '../../shared/widgets/glass_panel.dart';
import 'widgets/watchio_settings_scaffold.dart';

class PlaybackSettingsScreen extends StatefulWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  State<PlaybackSettingsScreen> createState() => _PlaybackSettingsScreenState();
}

class _PlaybackSettingsScreenState extends State<PlaybackSettingsScreen> {
  PlayerEngine _engine = PlayerEngine.auto;
  bool _hardwareDecoding = true;
  String _aspectRatio = 'fit';
  String _audioLang = 'en';
  String _subLang = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'auto', 'name': 'Automatic'},
    {'code': 'en', 'name': 'English'},
    {'code': 'tr', 'name': 'Turkish'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'it', 'name': 'Italian'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'ru', 'name': 'Russian'},
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'zh', 'name': 'Chinese'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final engineStr = await UserPreferences.getPlayerEngine();
    final hardware = await UserPreferences.getHardwareDecoding();
    final ratio = await UserPreferences.getPlayerAspectRatio();
    final audio = await UserPreferences.getAudioTrack();
    final sub = await UserPreferences.getSubtitleTrack();
    final languageCodes = _languages
        .map((language) => language['code'])
        .toSet();

    if (!mounted) return;
    setState(() {
      _engine = PlayerEngine.values.firstWhere(
        (e) => e.name == engineStr,
        orElse: () => PlayerEngine.auto,
      );
      _hardwareDecoding = hardware;
      _aspectRatio = ratio;
      _audioLang = languageCodes.contains(audio) ? audio : 'auto';
      _subLang = languageCodes.contains(sub) ? sub : 'auto';
    });
  }

  @override
  Widget build(BuildContext context) {
    return WatchioSettingsScaffold(
      title: 'PLAYER SETTINGS',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        children: [
          _buildSection('Player Engine', [
            _buildDropdown<PlayerEngine>(
              title: 'Preferred Engine',
              value: _engine,
              items: PlayerEngine.values,
              onChanged: (v) {
                if (v != null) {
                  setState(() => _engine = v);
                  UserPreferences.setPlayerEngine(v.name);
                }
              },
              labelBuilder: (e) => e.name.toUpperCase(),
            ),
          ]),
          const SizedBox(height: 10),
          _buildSection('Hardware Acceleration', [
            SwitchListTile(
              title: const Text(
                'Enable Hardware Decoding',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Uses GPU for video decoding if supported',
                style: TextStyle(color: Colors.white54),
              ),
              value: _hardwareDecoding,
              activeThumbColor: const Color(0xFFC12CFF),
              onChanged: (v) {
                setState(() => _hardwareDecoding = v);
                UserPreferences.setHardwareDecoding(v);
              },
            ),
          ]),
          const SizedBox(height: 10),
          _buildSection('Preferred Languages', [
            _buildDropdown<String>(
              title: 'Audio Language',
              value: _audioLang,
              items: _languages.map((l) => l['code']!).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _audioLang = v);
                  UserPreferences.setAudioTrack(v);
                }
              },
              labelBuilder: (c) =>
                  _languages.firstWhere((l) => l['code'] == c)['name']!,
            ),
            const Divider(color: Colors.white10),
            _buildDropdown<String>(
              title: 'Subtitle Language',
              value: _subLang,
              items: _languages.map((l) => l['code']!).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _subLang = v);
                  UserPreferences.setSubtitleTrack(v);
                }
              },
              labelBuilder: (c) =>
                  _languages.firstWhere((l) => l['code'] == c)['name']!,
            ),
          ]),
          const SizedBox(height: 10),
          _buildSection('Default Aspect Ratio', [
            _buildDropdown<String>(
              title: 'Aspect Ratio',
              value: _aspectRatio,
              items: ['fit', 'fill', 'stretch', '16:9', '4:3'],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _aspectRatio = v);
                  UserPreferences.setPlayerAspectRatio(v);
                }
              },
              labelBuilder: (s) => s.toUpperCase(),
            ),
          ]),
        ],
      ),
    ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF00B7FF),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String title,
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) labelBuilder,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: DropdownButton<T>(
        value: value,
        dropdownColor: const Color(0xFF1A1D29),
        underline: const SizedBox(),
        items: items
            .map(
              (i) => DropdownMenuItem(
                value: i,
                child: Text(
                  labelBuilder(i),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
