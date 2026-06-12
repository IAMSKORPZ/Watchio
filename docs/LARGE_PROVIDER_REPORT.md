# BingieTV Large Provider Report

## Target Scale
- Live TV: 9,870+ channels
- Movies: 28,000+
- Series: 12,000+
- EPG: 500,000+ entries

## Memory Hot Spots
- Xtream API imports still decode full JSON responses before database insertion.
- M3U parser still returns a full parsed list after isolate parsing.
- Category detail previously loaded a full category into memory. Phase 6 changes this to paged reads.
- Poster/logo image loading can pressure low-memory TV devices. Content cards now cap decode width.
- `AppState` and `PlaylistContentState` still contain global mutable lists/maps that can hold large provider data.

## Startup Bottlenecks
- App startup is mostly light, but service locator setup is now measured with `PerformanceService`.
- Provider switching remains metadata-first from Phase 2.
- Returning to large provider screens can still trigger category/home load work.

## Parsing Bottlenecks
- M3U parsing already uses `compute` in import paths, so it does not directly block UI.
- Parser still reads full source text and splits all lines.
- No streaming parse-to-database writer exists yet.
- EPG parsing/caching is not yet implemented at scale.

## Search Bottlenecks
- Search uses SQL `contains`/LIKE, not FTS.
- Search results were queried on every keystroke. Phase 6 adds debounce and in-memory recent-result cache.
- Search is capped to 50 results to prevent large result widget trees.

## Cache Bottlenecks
- Image cache policy is mostly package default.
- Phase 6 adds a temporary cache cleanup policy with max age and max size.
- Full remote/provider cache sizing still needs platform-specific tuning.

## UI Bottlenecks
- Grid/list views use builder constructors, so visible widgets are virtualized.
- Category detail no longer renders entire datasets; it loads pages and appends through infinite scroll.
- Horizontal home rows still use list builders but should be hardware-tested with huge category counts.

## Optimizations Applied
- Added paged result model.
- Added paged category content loading.
- Added DB/repository offset support for live, movies, series, M3U items, and M3U series.
- Added infinite scroll to category detail grids.
- Added debounced/cached search.
- Added debug performance metrics for startup, provider switching, category loading, and search.
- Added cache cleanup policy.

## Remaining Risks
- Xtream and M3U import pipelines still need chunked streaming writes.
- EPG must not be loaded as one full in-memory XML/JSON document.
- SQL indexes/FTS are still needed for reliable 50,000+ item search.
- Firestick 4K and Firestick Lite hardware profiling is still required.
