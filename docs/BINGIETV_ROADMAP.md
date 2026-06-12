# BingieTV Migration Roadmap

## Phase 2: Provider Manager
- Add provider registry and active provider selection.
- Normalize Xtream and M3U provider metadata.
- Add provider health checks and refresh status.
- Keep existing Xtream/M3U flows intact.
- Add import safety: validate before replacing old data.

## Phase 3: Remote Branding System
- Add local branding config model.
- Add remote branding fetch with fallback.
- Support app name, logo, colors, support links, and legal text.
- Cache branding and apply at startup.

## Phase 4: GitHub Auto Updates
- Add release feed checker.
- Add Windows update prompt and installer download flow.
- Add Android APK update check for non-store distribution.
- Add version/channel metadata.

## Phase 5: Android TV And Firestick Optimization
- Add Android TV manifest entries, banner, and launcher support.
- Audit D-pad focus and back behavior.
- Add TV-safe layout spacing.
- Profile memory and image cache on Firestick-class hardware.
- Validate remote-first playback controls.

## Phase 6: Stalker Portal Support
- Add Stalker provider model and auth flow.
- Implement portal handshake/session handling.
- Map Stalker live, VOD, series, and EPG data to shared domain models.
- Add provider-specific errors and diagnostics.

## Phase 7: Performance Refactor
- Add streaming/chunked import pipeline.
- Add DB indexes and FTS search.
- Add paginated repository APIs.
- Move heavy parsing and model conversion off UI isolate.
- Add import staging and rollback.
- Add large-provider benchmark suite for 9,870+ channels, 28,000+ movies, and 12,000+ series.
