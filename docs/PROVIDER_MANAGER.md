# BingieTV Provider Manager

## Architecture
Phase 2 adds a provider abstraction without replacing existing playlist flows.

Core files:
- `lib/models/provider_model.dart`
- `lib/repositories/provider_repository.dart`
- `lib/controllers/provider_controller.dart`
- `lib/screens/settings/provider_list_screen.dart`
- `lib/screens/settings/provider_form_screen.dart`

The provider model wraps existing Xtream and M3U playlist records. Existing `Playlist`, `PlaylistService`, `IptvRepository`, `M3uRepository`, watch history, favorites, and player flows remain intact.

## Data Flow
1. Settings opens `ProviderListScreen`.
2. `ProviderController` loads providers through `ProviderRepository`.
3. Repository reads stored provider metadata from SharedPreferences.
4. Repository also reads existing playlists and bridges any missing playlist into a provider record.
5. Switching a provider clears active app session/cache state and sets the selected playlist id as last used.
6. Navigation continues through existing Xtream/M3U home screens.

Provider switching does not import all channels, movies, or series. It only switches active provider context and lets existing home/category flows load metadata as needed.

## Provider Lifecycle
- Create: validate provider, save provider metadata, save compatible playlist.
- Update: validate provider, update provider metadata, update compatible playlist.
- Delete: delete provider metadata and matching playlist.
- Enable/disable: toggles provider availability.
- Set default: marks one provider as default.
- Switch: clears active session/cache and updates last-used provider.
- Health check: updates status and failure metadata.

## Storage Design
Provider metadata is stored as JSON in SharedPreferences under a versioned key:

`bingietv.providers.v1`

This keeps Phase 2 small and avoids Drift schema churn. Existing IPTV data remains in Drift. The repository interface isolates storage so Phase 7 can migrate provider metadata to Isar or another local store.

Provider fields:
- Common: `id`, `type`, `name`, `createdAt`, `updatedAt`, `lastUsed`, `lastConnected`, `enabled`, `isDefault`, `status`, `lastFailureReason`
- Xtream Codes: `serverUrl`, `username`, `password`
- M3U URL: `playlistUrl`, `epgUrl`
- M3U File: `localFilePath`, `epgUrl`

## Validation
Validation runs before saving:
- Xtream Codes requires valid HTTP/HTTPS URL, username, and password.
- M3U URL requires valid HTTP/HTTPS playlist URL.
- M3U File requires an existing readable local file path.

Invalid providers are not persisted.

## Status Checking
Status values:
- `online`
- `offline`
- `authFailed`
- `unknown`

Xtream health checks call `player_api.php` through the existing `IptvRepository`.

M3U URL health checks open the playlist URL and check HTTP status.

M3U File health checks validate file access.

Checks run asynchronously through the controller and do not block initial page rendering.

## Future Extension Points
The provider model can be extended for:
- Stalker Portal
- Single stream login
- Local media library
- Future cloud sync
- Remote branding ownership
- Provider-specific update channels

New provider types should be added behind `ProviderRepository`, not directly into UI screens.

## Migration Notes
- Existing playlists are bridged into providers on first Provider Manager load.
- Provider ids intentionally match playlist ids for backward compatibility.
- Dart package imports remain `another_iptv_player`; package rename was deferred in Phase 1.
- SharedPreferences storage is not the final scale target. It is a Phase 2 foundation until Isar/Drift migration is designed.

## Known Issues Found During Phase 2
- Flutter CLI is unavailable in this environment, so runtime verification is blocked.
- Android Gradle wrapper scripts are missing.
- Provider Manager add flow creates metadata and compatible playlist only; it does not import all content by design.
- Existing legacy playlist creation screens still work and are bridged into Provider Manager after load.
