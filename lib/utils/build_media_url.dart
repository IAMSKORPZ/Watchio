import 'package:another_iptv_player/services/app_state.dart';

import '../models/content_type.dart';
import '../models/playlist_content_model.dart';

String buildMediaUrl(ContentItem contentItem) {
  var playlist = AppState.currentPlaylist!;
  String baseUrl = playlist.url!;
  if (baseUrl.endsWith('/')) {
    baseUrl = baseUrl.substring(0, baseUrl.length - 1);
  }

  switch (contentItem.contentType) {
    case ContentType.liveStream:
      return '$baseUrl/${playlist.username}/${playlist.password}/${contentItem.id}';
    case ContentType.vod:
      final ext = contentItem.containerExtension;
      final suffix = (ext != null && ext.isNotEmpty) ? '.$ext' : '';
      return '$baseUrl/movie/${playlist.username}/${playlist.password}/${contentItem.id}$suffix';
    case ContentType.series:
      final ext = contentItem.containerExtension;
      final suffix = (ext != null && ext.isNotEmpty) ? '.$ext' : '';
      return '$baseUrl/series/${playlist.username}/${playlist.password}/${contentItem.id}$suffix';
  }
}
