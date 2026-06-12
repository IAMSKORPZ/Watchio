# BingieTV Phase 1 Performance Audit

Target provider size:
- 9,870+ channels
- 28,000+ movies
- 12,000+ series

## Current Scale Verdict
Current architecture cannot be considered ready for this provider size without Phase 7 performance work.

SQLite can hold the records, but ingestion, parsing, querying, and UI rendering are not designed as a streaming/chunked pipeline.

## Large Playlist Bottlenecks
- Xtream API responses decode entire JSON payloads into memory.
- M3U parser reads the full file/URL content, splits every line, and returns one full list.
- M3U import builds series structures after parsing, adding more memory pressure.
- Refresh paths delete old playlist data before full replacement, creating risk if refresh fails mid-way.

## Memory Issues
- Full list decode for 49,000+ provider records may spike memory on Android TV/Firestick.
- Image-heavy grids may create cache pressure if not tuned for TV devices.
- `AppState` can hold large current lists globally.

## Startup Issues
- App initialization itself is light, but returning to a large last playlist can trigger heavy DB loads.
- Category home screens may load broad datasets before the user needs them.

## UI Freezes
- Some parsing is run through `compute`, which helps.
- Database reads and model conversion still return large lists, which can jank when pushed into widgets.
- Grid screens need paging/windowing for very large categories.

## Parsing Bottlenecks
- M3U attribute parsing uses regex per `#EXTINF` line.
- Content type detection is filename/path heuristic based.
- No streaming parser or incremental DB writer.

## Database Limitations
- No FTS tables for search.
- No explicit indexes found for common filters like playlist/category/content type/search fields.
- Some count methods fetch rows and count in Dart instead of SQL count.
- `deleteDatabase()` targets `playlists.sqlite`, while active Drift database name is `another-iptv-player`; this looks stale.

## Required Performance Direction
- Chunked provider import.
- Streaming M3U parser.
- Transactional refresh with staging tables or import sessions.
- SQL indexes and FTS search.
- Paginated DB reads.
- Lazy category/content loading.
- Memory profiling on low-end Android TV/Firestick hardware.
