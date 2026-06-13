import 'package:another_iptv_player/database/database.dart';
import 'package:another_iptv_player/services/service_locator.dart';
import 'package:drift/drift.dart';

class EpgStorageService {
  final AppDatabase database;

  EpgStorageService({AppDatabase? database}) : database = database ?? getIt<AppDatabase>();

  Future<void> ensureSchema() async {
    await database.customStatement('''
CREATE TABLE IF NOT EXISTS epg_channels(
  playlist_id TEXT NOT NULL,
  epg_channel_id TEXT NOT NULL,
  display_name TEXT NOT NULL,
  icon_url TEXT,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY(playlist_id, epg_channel_id)
)
''');
    await database.customStatement('''
CREATE TABLE IF NOT EXISTS epg_programs(
  playlist_id TEXT NOT NULL,
  epg_channel_id TEXT NOT NULL,
  program_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  start_time INTEGER NOT NULL,
  end_time INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY(playlist_id, epg_channel_id, program_id)
)
''');
    await database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_epg_program_window ON epg_programs(playlist_id, epg_channel_id, start_time, end_time)',
    );
    await database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_epg_channel_name ON epg_channels(playlist_id, display_name)',
    );
  }

  Future<List<EpgProgramWindow>> getProgramsForWindow({
    required String playlistId,
    required String epgChannelId,
    required DateTime start,
    required DateTime end,
    int limit = 200,
  }) async {
    await ensureSchema();
    final rows = await database.customSelect(
      '''
SELECT program_id, title, description, start_time, end_time
FROM epg_programs
WHERE playlist_id = ? AND epg_channel_id = ?
  AND start_time < ? AND end_time > ?
ORDER BY start_time ASC
LIMIT ?
''',
      variables: [
        Variable.withString(playlistId),
        Variable.withString(epgChannelId),
        Variable.withInt(end.millisecondsSinceEpoch),
        Variable.withInt(start.millisecondsSinceEpoch),
        Variable.withInt(limit),
      ],
    ).get();
    return rows
        .map(
          (row) => EpgProgramWindow(
            programId: row.read<String>('program_id'),
            title: row.read<String>('title'),
            description: row.readNullable<String>('description'),
            start: DateTime.fromMillisecondsSinceEpoch(row.read<int>('start_time')),
            end: DateTime.fromMillisecondsSinceEpoch(row.read<int>('end_time')),
          ),
        )
        .toList();
  }
}

class EpgProgramWindow {
  final String programId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;

  const EpgProgramWindow({
    required this.programId,
    required this.title,
    required this.start,
    required this.end,
    this.description,
  });
}
