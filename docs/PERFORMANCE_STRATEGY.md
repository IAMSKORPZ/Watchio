# BingieTV Performance Strategy

## Architecture Direction
BingieTV should treat provider content as database-backed pages, not app-wide lists.

Current Phase 6 rule:
- Startup loads app state and provider metadata only.
- Provider switching loads metadata/categories only.
- Category screens load content one page at a time.
- Search returns capped, cached, debounced result windows.

## Pagination
Default page size is `60` items through `ContentService.defaultPageSize`.

Supported paged paths:
- Xtream live streams by category
- Xtream movies by category
- Xtream series by category
- M3U live/VOD items by category
- M3U series by category

The UI uses infinite scroll and only requests the next page near the end of the current grid.

## Virtualization
Flutter `GridView.builder` and `ListView.builder` remain the required pattern for large datasets.

Avoid:
- `Column(children: allItems.map(...))`
- Rendering full provider libraries
- Sorting/filtering all items in Dart when a DB query can do it

## Background Processing
Existing M3U import paths use `compute`.

Next required work:
- Streaming M3U parser
- Chunked DB inserts
- EPG parser isolate
- Metadata normalization isolate for large imports

## Search
Phase 6 search behavior:
- 300 ms debounce
- 50 result cap
- Recent-result memory cache
- Debug timing through `PerformanceService`

Future plan:
- Add SQLite FTS5 or Isar indexes.
- Use prefix/token tables for TV remote search.
- Keep result windows paged.

## Image Strategy
Current safeguards:
- `CachedNetworkImage` async loading
- Placeholder/error fallback
- Content card decode width capped

Future safeguards:
- Platform-specific image cache limits
- Poster prefetch disabled or bounded on Firestick
- CDN resizing if remote branding/provider supports it

## EPG Strategy
Do not load full EPG into memory.

Future design:
- Parse EPG in chunks.
- Store EPG by provider/channel/time window.
- Query EPG by channel and visible time range.
- Expire old entries with cache policy.

## Cache Policy
Phase 6 adds `CachePolicyService`.

Defaults:
- Max age: 14 days
- Max temporary cache size: 256 MB

Cleanup runs after startup setup and does not block `runApp`.

## Debug Metrics
`PerformanceService` tracks debug-only timings:
- `startup_setup`
- `provider_switch`
- `category_load`
- `search`

Metrics are kept in memory with a 200-entry cap.

## Future Isar Migration Plan
Do not add Isar until database contracts are isolated.

Migration order:
1. Keep repositories as the app boundary.
2. Add paged repository interfaces for all content types.
3. Add import sessions and staging writes.
4. Add equivalent Isar collections/indexes.
5. Backfill from Drift or re-import provider content.
6. Switch repositories behind feature flags.
7. Remove old Drift paths only after parity tests.

## Remaining Risks
- Full Xtream JSON decode can still spike memory.
- Full M3U parse result can still spike memory.
- EPG support is not scale-ready yet.
- Category genre/sort still operates on loaded pages only; full-category sort requires DB-backed ordering.
