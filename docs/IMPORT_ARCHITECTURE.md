# BingieTV Import Architecture

## Goal
Phase 7 removes the largest import memory bottlenecks without adding Isar or Stalker.

Target scale:
- 9,870+ live channels
- 28,000+ movies
- 12,000+ series
- 500,000+ EPG entries

## Core Files
- `lib/models/import_progress_model.dart`
- `lib/models/import_session_model.dart`
- `lib/services/streaming_json_array_decoder.dart`
- `lib/services/xtream_streaming_import_service.dart`
- `lib/services/streaming_m3u_import_service.dart`

## Xtream Data Flow
1. `IptvController` starts the import step.
2. `IptvRepository` calls `XtreamStreamingImportService`.
3. The service sends an HTTP request with `http.Client.send`.
4. Response bytes are decoded as text chunks.
5. `StreamingJsonArrayDecoder` emits one JSON object at a time from the top-level array.
6. Objects are converted to domain models in batches.
7. Batches are written to Drift.
8. Progress is reported after each batch.

Chunk size: `500` items.

The controller stores empty marker lists after success because category screens now read paged data from the database.

## M3U Data Flow
1. New M3U playlist screen creates the playlist record only.
2. `M3uDataLoaderScreen` passes source URL/file path to `StreamingM3uImportService`.
3. File or URL content is read line by line.
4. `#EXTINF` metadata is held only until the next URL line.
5. Items are assigned categories and written in batches.
6. Series/episode records are derived after stream pass.

Chunk size: `500` items.

## Progress
`ImportProgressModel` tracks:
- current item
- processed item count
- optional total
- percentage when total is known
- elapsed time
- estimated remaining time

## Cancellation
`ImportCancellationToken` supports cooperative cancellation.

Each importer checks the token between parsed items. Cancellation raises `ImportCancelledException`.

## Recovery
Current implementation clears old rows at import start and writes replacement rows in batches.

Required next hardening:
- import session table
- staging tables
- commit marker
- rollback cleanup
- retry from last completed batch

`ImportSessionModel` defines the future state contract.

## Future Isar Points
Do not migrate yet.

Migration-safe boundaries:
- import services emit batches
- repositories own persistence
- category screens read paged data
- import progress is model-based, not UI-coupled

Isar can replace Drift behind the repository/import service boundary later.
