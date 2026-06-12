import 'dart:convert';

import 'package:another_iptv_player/database/database.dart';
import 'package:another_iptv_player/models/api_configuration_model.dart';
import 'package:another_iptv_player/models/import_progress_model.dart';
import 'package:another_iptv_player/models/live_stream.dart';
import 'package:another_iptv_player/models/series.dart';
import 'package:another_iptv_player/models/vod_streams.dart';
import 'package:another_iptv_player/models/import_session_model.dart';
import 'package:another_iptv_player/services/import_recovery_service.dart';
import 'package:another_iptv_player/repositories/search_repository.dart';
import 'package:another_iptv_player/services/streaming_json_array_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class XtreamStreamingImportService {
  static const int defaultBatchSize = 500;

  final AppDatabase database;
  final http.Client client;
  final int batchSize;
  final StreamingJsonArrayDecoder _decoder = StreamingJsonArrayDecoder();
  final ImportRecoveryService recoveryService;
  final SearchRepository searchRepository;
  final Uuid _uuid = const Uuid();

  XtreamStreamingImportService({
    required this.database,
    http.Client? client,
    this.batchSize = defaultBatchSize,
    ImportRecoveryService? recoveryService,
    SearchRepository? searchRepository,
  })  : client = client ?? http.Client(),
        recoveryService = recoveryService ?? ImportRecoveryService(),
        searchRepository = searchRepository ?? SearchRepository(database: database);

  Future<ImportProgressModel> importLiveStreams({
    required ApiConfig config,
    required String playlistId,
    ImportProgressCallback? onProgress,
    ImportCancellationToken? cancellationToken,
  }) {
    return _import(
      config: config,
      playlistId: playlistId,
      action: 'get_live_streams',
      clearExisting: () => database.deleteLiveStreamsByPlaylistId(playlistId),
      writeJson: (items) {
        final rows = items.map((json) => LiveStream.fromJson(json, playlistId)).toList();
        return database.insertLiveStreams(rows);
      },
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
  }

  Future<ImportProgressModel> importMovies({
    required ApiConfig config,
    required String playlistId,
    ImportProgressCallback? onProgress,
    ImportCancellationToken? cancellationToken,
  }) {
    return _import(
      config: config,
      playlistId: playlistId,
      action: 'get_vod_streams',
      clearExisting: () => database.deleteVodStreamsByPlaylistId(playlistId),
      writeJson: (items) {
        final rows = items.map((json) => VodStream.fromJson(json, playlistId)).toList();
        return database.insertVodStreams(rows);
      },
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
  }

  Future<ImportProgressModel> importSeries({
    required ApiConfig config,
    required String playlistId,
    ImportProgressCallback? onProgress,
    ImportCancellationToken? cancellationToken,
  }) {
    return _import(
      config: config,
      playlistId: playlistId,
      action: 'get_series',
      clearExisting: () => database.deleteSeriesStreamsByPlaylistId(playlistId),
      writeJson: (items) {
        final rows = items.map((json) => SeriesStream.fromJson(json, playlistId)).toList();
        return database.insertSeriesStreams(rows);
      },
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
  }

  Future<ImportProgressModel> _import({
    required ApiConfig config,
    required String playlistId,
    required String action,
    required Future<void> Function() clearExisting,
    required Future<void> Function(List<Map<String, dynamic>> items) writeJson,
    ImportProgressCallback? onProgress,
    ImportCancellationToken? cancellationToken,
  }) async {
    final startedAt = DateTime.now();
    final session = ImportSessionModel(
      id: _uuid.v4(),
      providerId: playlistId,
      type: 'xtream:$action',
      status: ImportSessionStatus.running,
      startedAt: startedAt,
    );
    await recoveryService.saveSession(session);
    final params = Map<String, String>.from(config.baseParams)
      ..['action'] = action
      ..['_t'] = DateTime.now().millisecondsSinceEpoch.toString();
    final uri = Uri.parse('${config.baseUrl}/player_api.php')
        .replace(queryParameters: params);
    final request = http.Request('GET', uri)
      ..headers['Content-Type'] = 'application/json';
    final response = await client.send(request).timeout(const Duration(minutes: 2));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await recoveryService.markFailed(
        session.id,
        'HTTP ${response.statusCode}: Xtream import failed',
      );
      throw Exception('HTTP ${response.statusCode}: Xtream import failed');
    }

    await clearExisting();
    final batch = <Map<String, dynamic>>[];
    var processed = 0;
    final textStream = response.stream.transform(utf8.decoder);

    try {
      await for (final item in _decoder.decodeObjects(textStream)) {
        cancellationToken?.throwIfCancelled();
        batch.add(item);
        processed++;
        if (batch.length >= batchSize) {
          await writeJson(List<Map<String, dynamic>>.from(batch));
          batch.clear();
          onProgress?.call(
            ImportProgressModel(
              currentItem: action,
              processedItems: processed,
              startedAt: startedAt,
            ),
          );
        }
      }

      if (batch.isNotEmpty) await writeJson(batch);
    } catch (e) {
      await clearExisting();
      if (e is ImportCancelledException) {
        await recoveryService.markCancelled(session.id);
      } else {
        await recoveryService.markFailed(session.id, e.toString());
      }
      rethrow;
    }
    final done = ImportProgressModel(
      currentItem: action,
      processedItems: processed,
      startedAt: startedAt,
    );
    await recoveryService.markCompleted(session.id);
    await searchRepository.rebuildProviderIndex(playlistId);
    onProgress?.call(done);
    return done;
  }
}
