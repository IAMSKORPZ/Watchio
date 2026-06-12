# BingieTV Phase 1 Architecture Audit

## Current Folder Structure
- `lib/`: Flutter app code.
- `lib/controllers/`: Provider-backed view controllers for Xtream, M3U, playlists, favorites, history, locale, and theme.
- `lib/database/`: Drift schema, generated database code, and platform connections.
- `lib/models/`: Domain models for playlists, Xtream responses, M3U items, categories, favorites, and watch history.
- `lib/repositories/`: Data access wrappers for Xtream, M3U, favorites, and preferences.
- `lib/screens/`: App screens for playlist selection, Xtream Codes, M3U, live, movies, series, search, settings, and history.
- `lib/services/`: Service locator, app state, content state, player state, playlist service, M3U parsing, event bus, and watch history service.
- `lib/widgets/`: Shared UI widgets, player controls, category grids, watch history UI, and cards.
- `android/`, `windows/`, `ios/`, `macos/`, `linux/`, `web/`: Flutter platform runners.
- `native/ios/`: Separate native Swift iOS rewrite with MPV player and SQLite stack.
- `docs/`: Existing project website/docs plus this Phase 1 audit.

## State Management Approach
- Uses `provider` with `ChangeNotifierProvider` in `lib/main.dart`.
- Uses `get_it` service locator for `AppDatabase` and audio handler.
- Uses static global state in `AppState` for current playlist and repositories.
- Uses a simple event bus for player and UI events.

## Networking Layer
- Xtream Codes uses `http` in `IptvRepository`.
- Xtream endpoints use `player_api.php` actions for account info, categories, live streams, VOD, series, VOD info, and series info.
- M3U URL loading uses `dart:io` `HttpClient` in `M3uParser`.
- No shared retry, timeout, cancellation, rate-limit, or auth refresh layer.

## IPTV Providers Supported
- Xtream Codes: supported.
- M3U URL: supported.
- M3U local file: supported.
- Stalker Portal: not supported.
- Provider manager/multiple remote provider profiles: not yet implemented.

## Video Player Implementation
- Flutter app uses `media_kit`, `media_kit_video`, and `media_kit_libs_video`.
- Player state lives in `lib/services/player_state.dart`.
- UI controls live in `lib/widgets/video_widget.dart` and `lib/widgets/player-buttons/`.
- Background audio/media notification uses `audio_service`.
- Native iOS rewrite uses MPV in `native/ios/another-iptv-player/MPVPlayer/`.

## Database And Storage
- Drift/SQLite database in `lib/database/database.dart`.
- Tables include playlists, categories, user/server info, live streams, VOD streams, series streams, series info, seasons, episodes, watch history, M3U items, M3U series, M3U episodes, and favorites.
- Shared preferences store user settings, theme, player preferences, and last playlist data.
- Database schema version is `8`.

## Android Support
- Flutter Android runner exists.
- Android app id rebranded to `com.watchioiptv.app`.
- Uses foreground media playback permissions and `audio_service` activity/service.
- Android TV intent/category support is not explicitly configured.

## Windows Support
- Flutter Windows runner exists.
- Windows window title and executable metadata rebranded to BingieTV.
- NSIS installer script exists and was rebranded.
- Windows build could not be verified locally because Flutter CLI is unavailable.

## TV Support
- UI includes responsive layouts and TV-like content grids.
- Android TV/Firestick support is partial only.
- Missing Leanback launcher category, banner, D-pad focus audit, overscan handling, remote-first navigation validation, and TV-specific performance QA.

## Existing Features
- Playlist creation and selection.
- Xtream Codes login.
- M3U URL import.
- M3U file import.
- Live channels, movies, and series browsing.
- Category views.
- Search.
- Favorites.
- Watch history and continue watching.
- Video playback with subtitles, player controls, gestures, and background play setting.
- Settings for language, theme, subtitles, gestures, category visibility, and refresh.

## Technical Debt
- Global mutable `AppState` creates hidden dependencies.
- Controllers mix UI orchestration, caching, and repository calls.
- Some parsing logic is duplicated between `M3uParser` and `M3uController`.
- Large Drift file mixes schema, migrations, conversions, and query logic.
- No clear domain boundary between provider data, cached data, and UI view models.
- Package name remains `another_iptv_player`; changing it would require broad import migration, deferred to avoid rewrite risk.
- Some generated files are committed, including `database.g.dart`.

## Performance Bottlenecks
- Large Xtream responses are decoded into full in-memory lists before insertion.
- M3U parsing splits full file into all lines, then builds full item lists in memory.
- Bulk imports use batches, but no chunked parse-to-database streaming.
- Several database reads return whole playlist/category collections before filtering in UI.
- Search uses `contains`/`LIKE` without dedicated full-text index.
- Images are loaded through cached network image, but list prefetch and cache sizing need scale testing.

## Scale Readiness
Target size: 9,870+ channels, 28,000+ movies, 12,000+ series.

Current architecture is partial for this scale. SQLite can store the data, but ingestion and UI flows are likely to hit memory, startup, and jank issues because parsing and API loading are list-based, not stream/chunk-based.
