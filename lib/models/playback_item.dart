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

  factory PlaybackItem.fromContentItem(ContentItem item, {Duration startPosition = Duration.zero, Map<String, String>? headers}) {
    final Map<String, String> finalHeaders = headers ?? {
      'User-Agent': 'IPTVSmartersPlayer',
      'Accept': '*/*',
    };
    
    return PlaybackItem(
      id: item.id,
      url: item.url,
      title: item.name,
      subtitle: item.seriesStream?.name,
      imagePath: item.imagePath,
      contentType: item.contentType,
      headers: finalHeaders,
      startPosition: startPosition,
      originalItem: item,
    );
  }

  bool get isLive => contentType == ContentType.liveStream;

  PlaybackItem copyWith({
    String? id,
    String? url,
    String? title,
    String? subtitle,
    String? imagePath,
    ContentType? contentType,
    Map<String, String>? headers,
    Duration? startPosition,
    ContentItem? originalItem,
  }) {
    return PlaybackItem(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imagePath: imagePath ?? this.imagePath,
      contentType: contentType ?? this.contentType,
      headers: headers ?? this.headers,
      startPosition: startPosition ?? this.startPosition,
      originalItem: originalItem ?? this.originalItem,
    );
  }
}
