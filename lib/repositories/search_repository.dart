import 'package:another_iptv_player/database/database.dart';
import 'package:another_iptv_player/models/content_type.dart';
import 'package:another_iptv_player/models/paged_result.dart';
import 'package:another_iptv_player/models/playlist_content_model.dart';
import 'package:another_iptv_player/services/performance_service.dart';
import 'package:another_iptv_player/services/service_locator.dart';
import 'package:drift/drift.dart';

class SearchRepository {
  static const int defaultLimit = 50;

  final AppDatabase database;

  SearchRepository({AppDatabase? database})
    : database = database ?? getIt<AppDatabase>();

  Future<void> ensureSearchSchema() async {
    await database.customStatement('''
CREATE VIRTUAL TABLE IF NOT EXISTS content_search_fts USING fts5(
  playlist_id UNINDEXED,
  content_type UNINDEXED,
  content_id UNINDEXED,
  name,
  image_url UNINDEXED,
  tokenize = 'unicode61'
)
''');
    await database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_live_playlist_name ON live_streams(playlist_id, name)',
    );
    await database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_vod_playlist_name ON vod_streams(playlist_id, name)',
    );
    await database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_series_playlist_name ON series_streams(playlist_id, name)',
    );
  }

  Future<void> rebuildProviderIndex(String playlistId) async {
    await ensureSearchSchema();
    await database.transaction(() async {
      await database.customStatement(
        'DELETE FROM content_search_fts WHERE playlist_id = ?',
        [playlistId],
      );
      await database.customStatement(
        '''
INSERT INTO content_search_fts(playlist_id, content_type, content_id, name, image_url)
SELECT playlist_id, 'live', stream_id, name, stream_icon
FROM live_streams WHERE playlist_id = ?
''',
        [playlistId],
      );
      await database.customStatement(
        '''
INSERT INTO content_search_fts(playlist_id, content_type, content_id, name, image_url)
SELECT playlist_id, 'vod', stream_id, name, stream_icon
FROM vod_streams WHERE playlist_id = ?
''',
        [playlistId],
      );
      await database.customStatement(
        '''
INSERT INTO content_search_fts(playlist_id, content_type, content_id, name, image_url)
SELECT playlist_id, 'series', series_id, name, COALESCE(cover, '')
FROM series_streams WHERE playlist_id = ?
''',
        [playlistId],
      );
    });
  }

  Future<PagedResult<ContentItem>> search(
    String playlistId,
    String query, {
    ContentType? contentType,
    int page = 0,
    int limit = defaultLimit,
  }) {
    return PerformanceService.track('search', () async {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        return PagedResult(
          items: const [],
          page: page,
          pageSize: limit,
          hasNextPage: false,
        );
      }

      await ensureSearchSchema();
      final items = await _searchFts(
        playlistId,
        trimmed,
        page,
        limit,
        contentType: contentType,
      );
      if (items.isNotEmpty) {
        return PagedResult(
          items: items,
          page: page,
          pageSize: limit,
          hasNextPage: items.length == limit,
        );
      }

      final fallback = await _searchLike(
        playlistId,
        trimmed,
        page,
        limit,
        contentType: contentType,
      );
      return PagedResult(
        items: fallback,
        page: page,
        pageSize: limit,
        hasNextPage: fallback.length == limit,
      );
    }, metadata: {'playlistId': playlistId, 'page': page, 'limit': limit});
  }

  Future<List<ContentItem>> _searchFts(
    String playlistId,
    String query,
    int page,
    int limit, {
    ContentType? contentType,
  }) async {
    final typeName = _contentTypeName(contentType);
    final rows = await database
        .customSelect(
          '''
SELECT content_id, content_type, name, image_url
FROM content_search_fts
WHERE playlist_id = ? AND content_search_fts MATCH ?
  AND (? IS NULL OR content_type = ?)
LIMIT ? OFFSET ?
''',
          variables: [
            Variable.withString(playlistId),
            Variable.withString(_ftsQuery(query)),
            Variable<String>(typeName),
            Variable<String>(typeName),
            Variable.withInt(limit),
            Variable.withInt(page * limit),
          ],
        )
        .get();
    return rows.map(_rowToContentItem).toList();
  }

  Future<List<ContentItem>> _searchLike(
    String playlistId,
    String query,
    int page,
    int limit, {
    ContentType? contentType,
  }) async {
    final like = '%${query.replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
    final clauses = <String>[];
    final variables = <Variable>[
      Variable.withString(playlistId),
      Variable.withString(like),
      Variable.withString(playlistId),
      Variable.withString(like),
      Variable.withString(playlistId),
      Variable.withString(like),
    ];

    if (contentType == null || contentType == ContentType.liveStream) {
      clauses.add('''
SELECT stream_id AS content_id, 'live' AS content_type, name, stream_icon AS image_url
FROM live_streams WHERE playlist_id = ? AND name LIKE ? ESCAPE '\\'
''');
    }
    if (contentType == null || contentType == ContentType.vod) {
      clauses.add('''
SELECT stream_id AS content_id, 'vod' AS content_type, name, stream_icon AS image_url
FROM vod_streams WHERE playlist_id = ? AND name LIKE ? ESCAPE '\\'
''');
    }
    if (contentType == null || contentType == ContentType.series) {
      clauses.add('''
SELECT series_id AS content_id, 'series' AS content_type, name, COALESCE(cover, '') AS image_url
FROM series_streams WHERE playlist_id = ? AND name LIKE ? ESCAPE '\\'
''');
    }

    final activeVariables = switch (contentType) {
      ContentType.liveStream => variables.sublist(0, 2),
      ContentType.vod => variables.sublist(2, 4),
      ContentType.series => variables.sublist(4, 6),
      null => variables,
    };
    final rows = await database
        .customSelect(
          '''
${clauses.join('UNION ALL')}
LIMIT ? OFFSET ?
''',
          variables: [
            ...activeVariables,
            Variable.withInt(limit),
            Variable.withInt(page * limit),
          ],
        )
        .get();
    return rows.map(_rowToContentItem).toList();
  }

  String _ftsQuery(String query) {
    return query
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u00C0-\uFFFF]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '"${part.replaceAll('"', '""')}"*')
        .join(' ');
  }

  String? _contentTypeName(ContentType? type) {
    return switch (type) {
      ContentType.liveStream => 'live',
      ContentType.vod => 'vod',
      ContentType.series => 'series',
      null => null,
    };
  }

  ContentItem _rowToContentItem(QueryRow row) {
    final type = switch (row.read<String>('content_type')) {
      'live' => ContentType.liveStream,
      'vod' => ContentType.vod,
      'series' => ContentType.series,
      _ => ContentType.liveStream,
    };
    return ContentItem(
      row.read<String>('content_id'),
      row.read<String>('name'),
      row.read<String>('image_url'),
      type,
    );
  }
}
