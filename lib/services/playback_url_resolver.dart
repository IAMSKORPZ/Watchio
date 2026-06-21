import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/content_type.dart';
import '../models/playlist_content_model.dart';
import '../models/playlist_model.dart';
import 'secure_storage_service.dart';

class PlaybackUrlResolver {
  static Future<String?> resolveUrl({
    required ContentItem item,
    required Playlist playlist,
  }) async {
    final String streamId = item.id;
    final String playlistId = playlist.id;

    String? baseUrl = playlist.url;
    if (baseUrl == null || baseUrl.isEmpty) {
      debugPrint('PlaybackUrlResolver: baseUrl is empty for ${playlist.name}');
      return null;
    }

    String finalBaseUrl = baseUrl.trim();
    // Robust Sanitization
    try {
      final uri = Uri.parse(finalBaseUrl);
      finalBaseUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
    } catch (e) {
      if (finalBaseUrl.contains('/player_api.php')) {
        finalBaseUrl = finalBaseUrl.split('/player_api.php')[0];
      }
      if (finalBaseUrl.contains('/xmltv.php')) {
        finalBaseUrl = finalBaseUrl.split('/xmltv.php')[0];
      }
      if (finalBaseUrl.contains('/enigma2.php')) {
        finalBaseUrl = finalBaseUrl.split('/enigma2.php')[0];
      }
      if (finalBaseUrl.contains('/m3u_plus')) {
        finalBaseUrl = finalBaseUrl.split('/m3u_plus')[0];
      }

      while (finalBaseUrl.endsWith('/')) {
        finalBaseUrl = finalBaseUrl.substring(0, finalBaseUrl.length - 1);
      }

      if (!finalBaseUrl.startsWith('http://') && !finalBaseUrl.startsWith('https://')) {
        finalBaseUrl = 'http://$finalBaseUrl';
      }
    }

    if (playlist.type == PlaylistType.m3u) {
      final url = item.m3uItem?.url ?? (item.id.startsWith('http') ? item.id : null);
      if (url == null) {
        debugPrint('PlaybackUrlResolver: M3U URL missing for ${item.name}');
      }
      return url;
    }

    // Xtream or Stalker
    String? username = playlist.username;
    String? password = playlist.password;

    // Load from secure storage if empty
    if (username == null || username.isEmpty || password == null || password.isEmpty) {
      password = await SecureStorageService.instance.readProviderPassword(playlistId);
      final storedUser = await SecureStorageService.instance.readProviderSecret(playlistId, 'username');
      if (storedUser != null && storedUser.isNotEmpty) {
        username = storedUser;
      }
    }

    if (username == null || username.isEmpty || password == null || password.isEmpty) {
       debugPrint('PlaybackUrlResolver: Credentials missing for ${playlist.type.name} playlist: ${playlist.name}');
       return null;
    }

    String finalUrl;
    if (item.catchupStartTime != null && item.catchupDurationMinutes != null) {
      final startTimeStr = DateFormat('yyyy-MM-dd:HH-mm').format(item.catchupStartTime!);
      final duration = item.catchupDurationMinutes!;
      finalUrl = '$finalBaseUrl/timeshift/$username/$password/$duration/$startTimeStr/$streamId.ts';
    } else {
      switch (item.contentType) {
        case ContentType.liveStream:
          if (playlist.type == PlaylistType.xtream) {
            finalUrl = '$finalBaseUrl/live/$username/$password/$streamId.ts';
          } else if (playlist.type == PlaylistType.stalker) {
            finalUrl = '$finalBaseUrl/live/$streamId';
          } else {
            return null;
          }
          break;
        case ContentType.vod:
          final ext = item.containerExtension ?? 'mp4';
          final suffix = ext.isNotEmpty ? '.$ext' : '';
          if (playlist.type == PlaylistType.xtream) {
            finalUrl = '$finalBaseUrl/movie/$username/$password/$streamId$suffix';
          } else if (playlist.type == PlaylistType.stalker) {
            finalUrl = '$finalBaseUrl/vod/$streamId$suffix';
          } else {
            return null;
          }
          break;
        case ContentType.series:
          final ext = item.containerExtension ?? 'mp4';
          final suffix = ext.isNotEmpty ? '.$ext' : '';
          if (playlist.type == PlaylistType.xtream) {
            finalUrl = '$finalBaseUrl/series/$username/$password/$streamId$suffix';
          } else if (playlist.type == PlaylistType.stalker) {
            finalUrl = '$finalBaseUrl/series/$streamId$suffix';
          } else {
            return null;
          }
          break;
      }
    }

    // Masked logging
    final maskedUrl = finalUrl.replaceAllMapped(
        RegExp(r'/(live|movie|series|timeshift|vod)/([^/]+)/([^/]+)/'),
        (match) => '/${match.group(1)}/ *** / *** /');
    debugPrint('PlaybackUrlResolver: Resolved URL -> $maskedUrl');

    return finalUrl;
  }
}
