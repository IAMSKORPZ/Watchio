import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/provider_repository.dart';

class SettingsBackupService {
  static const _blockedFragments = [
    'password',
    'token',
    'secret',
    'mac',
    'credential',
    'secure_v1_',
    'provider',
    'playlist',
    'last_playlist',
  ];

  Future<String?> exportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final values = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      final lower = key.toLowerCase();
      if (_blockedFragments.any(lower.contains)) continue;
      final value = prefs.get(key);
      if (value is String ||
          value is bool ||
          value is int ||
          value is double ||
          value is List<String>) {
        values[key] = value;
      }
    }
    final payload = utf8.encode(
      const JsonEncoder.withIndent('  ').convert({
        'format': 'watchio-settings-v1',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'settings': values,
      }),
    );
    return FilePicker.saveFile(
      dialogTitle: 'Export Watchio settings',
      fileName: 'watchio-settings.json',
      bytes: payload,
    );
  }

  Future<int> importSettings() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null) return 0;
    final bytes = result.files.single.bytes;
    if (bytes == null) throw Exception('Unable to read backup file');
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map || decoded['format'] != 'watchio-settings-v1') {
      throw Exception('Invalid Watchio backup');
    }
    final settings = decoded['settings'];
    if (settings is! Map) throw Exception('Backup has no settings');
    final prefs = await SharedPreferences.getInstance();
    var restored = 0;
    for (final entry in settings.entries) {
      final key = entry.key.toString();
      final lower = key.toLowerCase();
      if (_blockedFragments.any(lower.contains)) continue;
      final value = entry.value;
      if (value is String) await prefs.setString(key, value);
      if (value is bool) await prefs.setBool(key, value);
      if (value is int) await prefs.setInt(key, value);
      if (value is double) await prefs.setDouble(key, value);
      if (value is List) {
        await prefs.setStringList(key, value.map((item) => '$item').toList());
      }
      restored++;
    }
    return restored;
  }

  Future<String?> exportProviderProfiles() async {
    final providers = await SharedPreferencesProviderRepository()
        .getAllProviders();
    final profiles = providers
        .map(
          (provider) => {
            'id': provider.id,
            'name': provider.name,
            'type': provider.type.name,
            'enabled': provider.enabled,
            'isDefault': provider.isDefault,
            'serverUrl': provider.serverUrl,
            'playlistUrl': provider.playlistUrl,
            'localFilePath': provider.localFilePath,
            'epgUrl': provider.epgUrl,
          },
        )
        .toList();
    return FilePicker.saveFile(
      dialogTitle: 'Export provider profiles',
      fileName: 'watchio-provider-profiles.json',
      bytes: utf8.encode(
        const JsonEncoder.withIndent(' ').convert({
          'format': 'watchio-provider-profiles-v1',
          'containsCredentials': false,
          'profiles': profiles,
        }),
      ),
    );
  }
}
