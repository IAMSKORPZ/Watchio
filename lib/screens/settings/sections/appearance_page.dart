import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../widgets/watchio_settings_scaffold.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ThemeManager>();

    return WatchioSettingsScaffold(
      title: 'APPEARANCE',
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
                  _ChoiceTile<AppThemeType>(
                    title: 'Colour Theme',
                    subtitle: 'Changes highlights, borders and glow',
                    value: manager.currentThemeType,
                    label: _themeName,
                    options: AppThemeType.values
                        .where((type) => type != AppThemeType.custom)
                        .toList(),
                    onChanged: manager.setThemeType,
                  ),
                  _ChoiceTile<String>(
                    title: 'Background Style',
                    subtitle: 'Changes backgrounds across the application',
                    value: manager.backgroundStyle,
                    label: _backgroundName,
                    options: const ['dynamic', 'dark', 'amoled'],
                    onChanged: manager.setBackgroundStyle,
                  ),
                  _ChoiceTile<String>(
                    title: 'Tile Style',
                    subtitle: 'Changes card corners and glass intensity',
                    value: manager.tileStyle,
                    label: _tileName,
                    options: const ['rounded', 'compact'],
                    onChanged: manager.setTileStyle,
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text('Animations', style: _titleStyle),
                    subtitle: Text(
                      'Enable smooth transitions and focus effects',
                      style: _subtitleStyle,
                    ),
                    value: manager.animationsEnabled,
                    onChanged: manager.setAnimationsEnabled,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _themeName(AppThemeType type) => switch (type) {
    AppThemeType.bingieNeon => 'Bingie Neon',
    AppThemeType.emerald => 'Emerald',
    AppThemeType.crimson => 'Crimson',
    AppThemeType.ocean => 'Ocean',
    AppThemeType.gold => 'Gold',
    AppThemeType.midnight => 'Midnight',
    AppThemeType.amoled => 'AMOLED',
    AppThemeType.custom => 'Custom',
  };

  static String _backgroundName(String value) => switch (value) {
    'dark' => 'Dark Gradient',
    'amoled' => 'AMOLED Black',
    _ => 'Dynamic Mesh',
  };

  static String _tileName(String value) =>
      value == 'compact' ? 'Compact Glass' : 'Rounded Glass';

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

class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.label,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final T value;
  final String Function(T) label;
  final List<T> options;
  final Future<void> Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
          dense: true,
          visualDensity: const VisualDensity(vertical: -3),
          title: Text(title, style: AppearancePage._titleStyle),
          subtitle: Text(subtitle, style: AppearancePage._subtitleStyle),
          trailing: DropdownButton<T>(
            value: value,
            dropdownColor: const Color(0xFF1A1D29),
            underline: const SizedBox.shrink(),
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            items: options
                .map(
                  (option) => DropdownMenuItem<T>(
                    value: option,
                    child: Text(label(option)),
                  ),
                )
                .toList(),
            onChanged: (option) {
              if (option != null) onChanged(option);
            },
          ),
        ),
        const Divider(color: Colors.white10, indent: 16, endIndent: 16),
      ],
    );
  }
}
