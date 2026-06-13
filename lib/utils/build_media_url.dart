import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:another_iptv_player/services/app_state.dart';

import '../models/content_type.dart';
import '../models/playlist_content_model.dart';

String buildMediaUrl(ContentItem contentItem) {
  final playlist = AppState.currentPlaylist;
  if (playlist == null) {
    debugPrint('buildMediaUrl: CRITICAL ERROR - AppState.currentPlaylist is NULL');
    return contentItem.id;
  }
  
  String baseUrl = playlist.url ?? '';
  if (baseUrl.isEmpty) {
    debugPrint('buildMediaUrl: CRITICAL ERROR - playlist.url is EMPTY');
    return contentItem.id;
  }

  // Robust Sanitization: Extract just the protocol, domain and port
  try {
    final uri = Uri.parse(baseUrl.trim());
    baseUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
  } catch (e) {
    debugPrint('buildMediaUrl: URI Parse Warning: $e');
    // Fallback to basic string cleaning
    baseUrl = baseUrl.trim();
    if (baseUrl.contains('/player_api.php')) baseUrl = baseUrl.split('/player_api.php')[0];
    if (baseUrl.contains('/xmltv.php')) baseUrl = baseUrl.split('/xmltv.php')[0];
    if (baseUrl.contains('/enigma2.php')) baseUrl = baseUrl.split('/enigma2.php')[0];
    if (baseUrl.contains('/m3u_plus')) baseUrl = baseUrl.split('/m3u_plus')[0];
    
    while (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      baseUrl = 'http://$baseUrl';
    }
  }

  final username = playlist.username ?? '';
  final password = playlist.password ?? '';

  if (username.isEmpty || password.isEmpty) {
    debugPrint('buildMediaUrl: CRITICAL ERROR - username or password is EMPTY for playlist: ${playlist.name}');
    return contentItem.id;
  }

  String finalUrl;
  
  // Handle Catchup first
  if (contentItem.catchupStartTime != null && contentItem.catchupDurationMinutes != null) {
    final startTimeStr = DateFormat('yyyy-MM-dd:HH-mm').format(contentItem.catchupStartTime!);
    final duration = contentItem.catchupDurationMinutes!;
    finalUrl = '$baseUrl/timeshift/$username/$password/$duration/$startTimeStr/${contentItem.id}.ts';
  } else {
    switch (contentItem.contentType) {
      case ContentType.liveStream:
        // Try the most compatible format for Media3/ExoPlayer
        finalUrl = '$baseUrl/live/$username/$password/${contentItem.id}.ts';
        break;
      case ContentType.vod:
        final ext = contentItem.containerExtension;
        final suffix = (ext != null && ext.isNotEmpty) ? '.$ext' : '';
        finalUrl = '$baseUrl/movie/$username/$password/${contentItem.id}$suffix';
        break;
      case ContentType.series:
        final ext = contentItem.containerExtension;
        final suffix = (ext != null && ext.isNotEmpty) ? '.$ext' : '';
        finalUrl = '$baseUrl/series/$username/$password/${contentItem.id}$suffix';
        break;
      default:
        finalUrl = contentItem.id;
    }
  }

  debugPrint('buildMediaUrl: Pipeline URL Generated -> $finalUrl');
  return finalUrl;
}
