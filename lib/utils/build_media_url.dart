import 'package:flutter/foundation.dart';
import 'package:another_iptv_player/services/app_state.dart';

import '../models/content_type.dart';
import '../models/playlist_content_model.dart';

String buildMediaUrl(ContentItem contentItem) {
  final playlist = AppState.currentPlaylist;
  if (playlist == null) {
    debugPrint('buildMediaUrl: AppState.currentPlaylist is NULL');
    return contentItem.id;
  }
  
  String baseUrl = playlist.url ?? '';
  if (baseUrl.isEmpty) {
    debugPrint('buildMediaUrl: playlist.url is EMPTY');
    return contentItem.id;
  }

  if (baseUrl.endsWith('/')) {
    baseUrl = baseUrl.substring(0, baseUrl.length - 1);
  }

  final username = Uri.encodeComponent(playlist.username ?? '');
  final password = Uri.encodeComponent(playlist.password ?? '');

  String finalUrl;
  switch (contentItem.contentType) {
    case ContentType.liveStream:
      // Standard Xtream Live URL pattern: domain:port/live/user/pass/id.ts
      // Some panels also support: domain:port/user/pass/id
      // Adding /live/ and .ts is the most compatible way for ExoPlayer
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

  if (!finalUrl.startsWith('http')) {
     debugPrint('buildMediaUrl: WARNING - Generated URL does not start with http: $finalUrl');
  }

  debugPrint('buildMediaUrl generated: $finalUrl');
  return finalUrl;
}
