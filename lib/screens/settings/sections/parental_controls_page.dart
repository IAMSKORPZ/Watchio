import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../controllers/xtream_code_home_controller.dart';
import '../../../services/secure_storage_service.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../category_settings_section.dart';
import '../widgets/watchio_settings_scaffold.dart';

class ParentalControlsPage extends StatefulWidget {
  const ParentalControlsPage({super.key});

  @override
  State<ParentalControlsPage> createState() => _ParentalControlsPageState();
}

class _ParentalControlsPageState extends State<ParentalControlsPage> {
  bool _pinEnabled = false;
  bool _settingsLocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pinEnabled = prefs.getBool('parental_pin_enabled') ?? false;
      _settingsLocked = prefs.getBool('parental_lock_settings') ?? false;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _changePin() async {
    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111525),
        title: const Text('Set Parental PIN'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(labelText: '4-digit PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (pin == null) return;
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN must contain exactly four digits.'),
          ),
        );
      }
      return;
    }
    await SecureStorageService.instance.saveProviderSecret(
      'parental',
      'pin',
      pin,
    );
    if (mounted) {
      setState(() => _pinEnabled = true);
      await _setBool('parental_pin_enabled', true);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Parental PIN updated.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return WatchioSettingsScaffold(
      title: 'PARENTAL CONTROLS',
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
                  SwitchListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -3),
                    title: const Text('Enable PIN'),
                    subtitle: const Text(
                      'Require PIN to access locked content',
                    ),
                    value: _pinEnabled,
                    activeThumbColor: accent,
                    onChanged: (value) {
                      setState(() => _pinEnabled = value);
                      _setBool('parental_pin_enabled', value);
                    },
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -3),
                    title: const Text('Change PIN'),
                    subtitle: const Text(
                      'Set a new 4-digit parental control PIN',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: _changePin,
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -3),
                    title: const Text('Lock Categories'),
                    subtitle: const Text(
                      'Choose which categories require a PIN',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategorySettingsScreen(
                          controller: context.read<XtreamCodeHomeController>(),
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -3),
                    title: const Text('Lock Settings'),
                    subtitle: const Text(
                      'Prevent unauthorized settings changes',
                    ),
                    value: _settingsLocked,
                    activeThumbColor: accent,
                    onChanged: (value) {
                      setState(() => _settingsLocked = value);
                      _setBool('parental_lock_settings', value);
                    },
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
