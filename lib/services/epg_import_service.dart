import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:another_iptv_player/models/import_progress_model.dart';
import 'package:another_iptv_player/services/epg_storage_service.dart';
import 'package:http/http.dart' as http;

class EpgImportService {
  static const int defaultBatchSize = 500;

  final EpgStorageService storage;
  final int batchSize;

  EpgImportService({
    EpgStorageService? storage,
    this.batchSize = defaultBatchSize,
  }) : storage = storage ?? EpgStorageService();

  Future<ImportProgressModel> importUrl({
    required String playlistId,
    required String url,
    ImportProgressCallback? onProgress,
    ImportCancellationToken? cancellationToken,
  }) async {
    final response = await http.Client().send(http.Request('GET', Uri.parse(url)));
    if (response.statusCode >= 400) {
      throw Exception('EPG import failed: HTTP ${response.statusCode}');
    }
    return _importLines(
      playlistId: playlistId,
      lines: response.stream.transform(utf8.decoder).transform(const LineSplitter()),
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
  }

  Future<ImportProgressModel> importFile({
    required String playlistId,
    required String filePath,
    ImportProgressCallback? onProgress,
    ImportCancellationToken? cancellationToken,
  }) {
    return _importLines(
      playlistId: playlistId,
      lines: File(filePath)
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter()),
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
  }

  Future<ImportProgressModel> _importLines({
    required String playlistId,
    required Stream<String> lines,
    ImportProgressCallback? onProgress,
    ImportCancellationToken? cancellationToken,
  }) async {
    await storage.ensureSchema();
    final startedAt = DateTime.now();
    final programs = <_ProgramRow>[];
    var processed = 0;
    String? channelId;
    final buffer = StringBuffer();

    Future<void> flushPrograms() async {
      if (programs.isEmpty) return;
      await storage.database.batch((batch) {
        for (final program in programs) {
          batch.customStatement(
            '''
INSERT OR REPLACE INTO epg_programs(
  playlist_id, epg_channel_id, program_id, title, description, start_time, end_time, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''',
            [
              playlistId,
              program.channelId,
              program.programId,
              program.title,
              program.description,
              program.start.millisecondsSinceEpoch,
              program.end.millisecondsSinceEpoch,
              DateTime.now().millisecondsSinceEpoch,
            ],
          );
        }
      });
      programs.clear();
    }

    await for (final rawLine in lines) {
      cancellationToken?.throwIfCancelled();
      processed++;
      final line = rawLine.trim();

      if (line.startsWith('<channel ')) {
        channelId = _attr(line, 'id');
        buffer.clear();
        buffer.write(line);
      } else if (channelId != null) {
        buffer.write(line);
        if (line.endsWith('</channel>')) {
          final xml = buffer.toString();
          await _upsertChannel(
            playlistId,
            channelId,
            _tag(xml, 'display-name') ?? channelId,
            _attr(xml, 'src'),
          );
          channelId = null;
          buffer.clear();
        }
      } else if (line.startsWith('<programme ')) {
        buffer.clear();
        buffer.write(line);
        if (line.endsWith('</programme>')) {
          final row = _parseProgram(buffer.toString());
          if (row != null) programs.add(row);
        }
      } else if (buffer.isNotEmpty) {
        buffer.write(line);
        if (line.endsWith('</programme>')) {
          final row = _parseProgram(buffer.toString());
          if (row != null) programs.add(row);
          buffer.clear();
        }
      }

      if (programs.length >= batchSize) await flushPrograms();
      if (processed % batchSize == 0) {
        onProgress?.call(
          ImportProgressModel(
            currentItem: 'epg',
            processedItems: processed,
            startedAt: startedAt,
          ),
        );
      }
    }

    await flushPrograms();
    final done = ImportProgressModel(
      currentItem: 'epg complete',
      processedItems: processed,
      startedAt: startedAt,
    );
    onProgress?.call(done);
    return done;
  }

  Future<void> _upsertChannel(
    String playlistId,
    String channelId,
    String displayName,
    String? iconUrl,
  ) {
    return storage.database.customStatement(
      '''
INSERT OR REPLACE INTO epg_channels(
  playlist_id, epg_channel_id, display_name, icon_url, updated_at
) VALUES (?, ?, ?, ?, ?)
''',
      [
        playlistId,
        channelId,
        displayName,
        iconUrl,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  _ProgramRow? _parseProgram(String xml) {
    final channel = _attr(xml, 'channel');
    final startRaw = _attr(xml, 'start');
    final stopRaw = _attr(xml, 'stop');
    if (channel == null || startRaw == null || stopRaw == null) return null;
    final start = _parseXmlTvTime(startRaw);
    final stop = _parseXmlTvTime(stopRaw);
    if (start == null || stop == null) return null;
    final title = _tag(xml, 'title') ?? 'Untitled';
    return _ProgramRow(
      channelId: channel,
      programId: '${channel}_${start.millisecondsSinceEpoch}',
      title: title,
      description: _tag(xml, 'desc'),
      start: start,
      end: stop,
    );
  }

  DateTime? _parseXmlTvTime(String value) {
    final match = RegExp(r'^(\d{14})').firstMatch(value);
    if (match == null) return null;
    final raw = match.group(1)!;
    return DateTime.utc(
      int.parse(raw.substring(0, 4)),
      int.parse(raw.substring(4, 6)),
      int.parse(raw.substring(6, 8)),
      int.parse(raw.substring(8, 10)),
      int.parse(raw.substring(10, 12)),
      int.parse(raw.substring(12, 14)),
    );
  }

  String? _attr(String xml, String name) {
    return RegExp('$name="([^"]*)"').firstMatch(xml)?.group(1);
  }

  String? _tag(String xml, String name) {
    final value = RegExp('<$name[^>]*>(.*?)</$name>', dotAll: true)
        .firstMatch(xml)
        ?.group(1);
    return value?.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _ProgramRow {
  final String channelId;
  final String programId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;

  const _ProgramRow({
    required this.channelId,
    required this.programId,
    required this.title,
    required this.start,
    required this.end,
    this.description,
  });
}
