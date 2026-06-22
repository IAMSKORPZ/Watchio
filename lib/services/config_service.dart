import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class ConfigService extends ChangeNotifier {
  static const String _configUrl =
      'https://raw.githubusercontent.com/IAMSKORPZ/Watchio/main/assets/images/gdsfad/dfgfsad/dfgfs/app_config.json';
  static const String _cacheKey = 'watchio_app_config_v3';
  static const String _lastUpdateKey = 'watchio_config_last_update_v3';

  AppConfig _config = AppConfig.defaults;
  AppConfig get config => _config;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // 1. Try to load from cache first for immediate UI availability
    await _loadFromCache();

    // 2. Check if we need to refresh (every 6 hours)
    if (await _shouldRefresh()) {
      await refresh();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _shouldRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Use refreshHours from config if available, fallback to 6
    final hours = _config.refreshHours > 0 ? _config.refreshHours : 6;
    final refreshInterval = Duration(hours: hours).inMilliseconds;

    return (now - lastUpdate) > refreshInterval;
  }

  Future<void> refresh() async {
    try {
      final response = await http
          .get(Uri.parse(_configUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _config = AppConfig.fromJson(data);
        await _saveToCache(response.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch remote config: $e');
      // resilience: keep using cached/defaults
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null) {
        final Map<String, dynamic> data = json.decode(cachedJson);
        _config = AppConfig.fromJson(data);
      }
    } catch (e) {
      debugPrint('Failed to load config from cache: $e');
    }
  }

  Future<void> _saveToCache(String jsonString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Failed to save config to cache: $e');
    }
  }
}
