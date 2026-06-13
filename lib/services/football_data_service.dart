import 'dart:convert';
import 'package:another_iptv_player/database/database.dart';
import 'package:another_iptv_player/services/service_locator.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import '../models/football_models.dart';

class FootballDataService {
  static const String _baseUrl = 'https://api.football-data.org/v4';
  static const String _apiKey = 'b6e92a7b9a4047879aac3f80110156d6'; // Example API key

  final AppDatabase _db = getIt<AppDatabase>();
  static const Duration _cacheDuration = Duration(minutes: 15);

  Future<List<FootballMatch>> getMatches({String? dateFrom, String? dateTo}) async {
    final cacheKey = 'matches_${dateFrom}_$dateTo';
    
    // Check DB cache
    final cached = await (_db.select(_db.footballCaches)..where((t) => t.cacheKey.equals(cacheKey))).getSingleOrNull();
    
    if (cached != null && DateTime.now().isBefore(cached.timestamp.add(_cacheDuration))) {
      final List<dynamic> decoded = json.decode(cached.data);
      return decoded.map((json) => FootballMatch.fromJson(json)).toList();
    }

    final queryParams = <String, String>{};
    if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
    if (dateTo != null) queryParams['dateTo'] = dateTo;

    try {
      final uri = Uri.parse('$_baseUrl/matches').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'X-Auth-Token': _apiKey});

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> matchesJson = responseData['matches'];
        
        // Save to DB cache
        await _db.into(_db.footballCaches).insertOnConflictUpdate(
          FootballCachesCompanion(
            cacheKey: Value(cacheKey),
            data: Value(json.encode(matchesJson)),
            timestamp: Value(DateTime.now()),
          ),
        );

        return matchesJson.map((json) => FootballMatch.fromJson(json)).toList();
      } else {
        // If API fails, try to return expired cache if exists
        if (cached != null) {
          final List<dynamic> decoded = json.decode(cached.data);
          return decoded.map((json) => FootballMatch.fromJson(json)).toList();
        }
        throw Exception('Failed to load football data: ${response.statusCode}');
      }
    } catch (e) {
      if (cached != null) {
        final List<dynamic> decoded = json.decode(cached.data);
        return decoded.map((json) => FootballMatch.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<List<FootballMatch>> getTodayMatches() async {
    final now = DateTime.now();
    final today = _formatDate(now);
    return getMatches(dateFrom: today, dateTo: today);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
