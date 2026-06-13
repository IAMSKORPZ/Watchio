import 'content_type.dart';
import 'playlist_content_model.dart';

class PlaybackItem {
  final String id;
  final String url;
  final String title;
  final String? subtitle;
  final String imagePath;
  final ContentType contentType;
  final Map<String, String> headers;
  final Duration startPosition;
  final ContentItem? originalItem;

  PlaybackItem({
    required this.id,
    required this.url,
    required this.title,
    this.subtitle,
    required this.imagePath,
    required this.contentType,
    this.headers = const {},
    this.startPosition = Duration.zero,
    this.originalItem,
  });

  factory PlaybackItem.fromContentItem(ContentItem item, {Duration startPosition = Duration.zero, Map<String, String> headers = const {}}) {
    return PlaybackItem(
      id: item.id,
      url: item.url,
      title: item.name,
      subtitle: item.seriesStream?.name,
      imagePath: item.imagePath,
      contentType: item.contentType,
      headers: headers,
      startPosition: startPosition,
      originalItem: item,
    );
  }

  bool get isLive => contentType == ContentType.liveStream;
}
