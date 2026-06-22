import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_v2_model.dart';

class AnnouncementService extends ChangeNotifier {
  static const String _url =
      'https://raw.githubusercontent.com/IAMSKORPZ/iamskorpz.github.io/master/config/announcements.json';
  static const String _cacheKey = 'watchio_announcements_cache';
  static const String _lastUpdateKey = 'watchio_announcements_last_update';
  static const String _dismissedIdKey = 'watchio_announcement_dismissed_id';

  List<AnnouncementV2Model> _announcements = [];
  List<AnnouncementV2Model> get announcements => _announcements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  Future<void> initialize() async {
    await _loadFromCache();
    await refresh();
  }

  Future<AnnouncementV2Model?> latestUndismissed() async {
    if (_announcements.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final dismissedId = prefs.getInt(_dismissedIdKey) ?? 0;
    final latest = _announcements.first;
    return latest.id > dismissedId ? latest : null;
  }

  Future<void> dismiss(AnnouncementV2Model announcement) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedIdKey, announcement.id);
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 10));
      debugPrint('Announcements Response: ${response.statusCode}');
      debugPrint('Announcements Body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> list = data['announcements'] ?? [];
        _announcements = list
            .map((e) => AnnouncementV2Model.fromJson(e))
            .toList();
        debugPrint('Parsed Announcements Count: ${_announcements.length}');

        // Sort by ID descending (assuming higher ID = newer) or date if needed.
        // ID is safer for "newest first" based on your example.
        _announcements.sort((a, b) => b.id.compareTo(a.id));

        await _saveToCache(response.body);
      }
    } catch (e) {
      debugPrint('Failed to fetch announcements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null) {
        final Map<String, dynamic> data = json.decode(cachedJson);
        final List<dynamic> list = data['announcements'] ?? [];
        _announcements = list
            .map((e) => AnnouncementV2Model.fromJson(e))
            .toList();
        _announcements.sort((a, b) => b.id.compareTo(a.id));
      }
    } catch (e) {
      debugPrint('Failed to load announcements from cache: $e');
    }
  }

  Future<void> _saveToCache(String jsonString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Failed to save announcements to cache: $e');
    }
  }
}
