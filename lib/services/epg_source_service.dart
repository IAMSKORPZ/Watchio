import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlist_model.dart';
import 'epg_import_service.dart';

class EpgSourceResult {
  const EpgSourceResult({required this.url, required this.label});
  final String url;
  final String label;
}

class EpgSourceService {
  EpgSourceService({http.Client? client, EpgImportService? importer})
    : _client = client ?? http.Client(),
      _importer = importer ?? EpgImportService();

  final http.Client _client;
  final EpgImportService _importer;

  static const builtInSources = <EpgSourceResult>[
    EpgSourceResult(
      label: 'Community public guide',
      url: 'https://worker-9dd4.onrender.com/guide.xml',
    ),
  ];

  Future<List<EpgSourceResult>> discover(Playlist playlist) async {
    final candidates = <EpgSourceResult>[];
    if (playlist.type == PlaylistType.xtream &&
        playlist.url?.isNotEmpty == true &&
        playlist.username?.isNotEmpty == true &&
        playlist.password?.isNotEmpty == true) {
      var base = playlist.url!;
      if (base.contains('/player_api.php')) {
        base = base.split('/player_api.php').first;
      }
      candidates.add(
        EpgSourceResult(
          label: 'Provider XMLTV',
          url:
              '$base/xmltv.php?username=${Uri.encodeQueryComponent(playlist.username!)}&password=${Uri.encodeQueryComponent(playlist.password!)}',
        ),
      );
    }

    if (playlist.type == PlaylistType.m3u &&
        playlist.url?.startsWith('http') == true) {
      final discovered = await _discoverM3uGuide(playlist.url!);
      if (discovered != null) {
        candidates.add(
          EpgSourceResult(label: 'Playlist XMLTV', url: discovered),
        );
      }
    }

    final valid = <EpgSourceResult>[];
    for (final candidate in [...candidates, ...builtInSources]) {
      if (await _isXmlTv(candidate.url)) valid.add(candidate);
    }
    return valid;
  }

  Future<EpgSourceResult> discoverAndImport({
    required Playlist playlist,
    void Function(String status)? onStatus,
  }) async {
    onStatus?.call('Scanning provider and fallback EPG sources…');
    final sources = await discover(playlist);
    if (sources.isEmpty) throw Exception('No working XMLTV source found');
    final source = sources.first;
    onStatus?.call('Importing ${source.label}…');
    await _importer.importUrl(playlistId: playlist.id, url: source.url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'epg_last_refresh_${playlist.id}',
      DateTime.now().millisecondsSinceEpoch,
    );
    return source;
  }

  static Future<void> refreshIfDue(Playlist playlist) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('epg_auto_refresh') ?? true)) return;
    final interval =
        int.tryParse(prefs.getString('epg_refresh_interval') ?? '24') ?? 24;
    final last = prefs.getInt('epg_last_refresh_${playlist.id}') ?? 0;
    final dueAt = DateTime.fromMillisecondsSinceEpoch(
      last,
    ).add(Duration(hours: interval));
    if (DateTime.now().isBefore(dueAt)) return;
    try {
      await EpgSourceService().discoverAndImport(playlist: playlist);
    } catch (_) {
      // Automatic refresh is best-effort and must never block app startup.
    }
  }

  Future<bool> _isXmlTv(String url) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers['Range'] = 'bytes=0-8191';
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 400) return false;
      final prefix = await response.stream
          .transform(utf8.decoder)
          .take(4)
          .join()
          .timeout(const Duration(seconds: 8));
      return prefix.contains('<tv') || prefix.contains('<channel');
    } catch (_) {
      return false;
    }
  }

  Future<String?> _discoverM3uGuide(String playlistUrl) async {
    try {
      final response = await _client
          .get(Uri.parse(playlistUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 400) return null;
      final end = response.body.length < 16384 ? response.body.length : 16384;
      final header = response.body.substring(0, end);
      return RegExp(
        r'''(?:url-tvg|x-tvg-url)=["']([^"']+)["']''',
        caseSensitive: false,
      ).firstMatch(header)?.group(1);
    } catch (_) {
      return null;
    }
  }
}
