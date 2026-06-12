# BingieTV Remote Branding

## Architecture
Phase 3 adds a generic remote configuration layer. GitHub is only the first implementation.

Core files:
- `lib/providers/remote_config_provider.dart`
- `lib/providers/github_remote_config_provider.dart`
- `lib/services/remote_config_service.dart`
- `lib/services/branding_service.dart`
- `lib/controllers/branding_controller.dart`
- `lib/models/branding_model.dart`
- `lib/models/theme_model.dart`
- `lib/models/announcement_model.dart`
- `lib/models/maintenance_model.dart`
- `lib/models/update_info_model.dart`

`RemoteConfigProvider` is the provider abstraction. Future Cloudflare R2, AWS S3, Firebase, custom API, or custom website providers should implement that interface.

## Data Flow
1. `BrandingController` starts from built-in defaults.
2. Controller calls `BrandingService`.
3. `BrandingService` calls `RemoteConfigService`.
4. `RemoteConfigService` asks the configured `RemoteConfigProvider` for branding, theme, announcements, maintenance, and update info.
5. Valid remote data is cached locally.
6. UI reads state from `BrandingController`.

The app does not wait for remote config before launching.

## JSON Shape
Example root config:

```json
{
  "branding": {
    "appName": "BingieTV",
    "logoUrl": "https://example.com/logo.png",
    "splashUrl": "https://example.com/splash.png",
    "iconUrl": "https://example.com/icon.png",
    "supportUrl": "https://example.com/support",
    "websiteUrl": "https://example.com",
    "discordUrl": "https://discord.gg/example"
  },
  "theme": {
    "primaryColor": "#E50914",
    "secondaryColor": "#141414",
    "accentColor": "#FFFFFF",
    "backgroundColor": "#0A0A0A",
    "cardColor": "#1A1A1A",
    "textColor": "#FFFFFF"
  },
  "announcements": [
    {
      "title": "Welcome",
      "body": "Welcome to BingieTV.",
      "createdAt": "2026-06-05T00:00:00Z",
      "priority": 1,
      "expiresAt": "2026-12-31T00:00:00Z"
    }
  ],
  "maintenance": {
    "enabled": false,
    "title": "Maintenance",
    "message": "Scheduled maintenance.",
    "allowPlayback": true,
    "allowLogin": true
  },
  "updateInfo": {
    "latestVersion": "0.0.1",
    "minimumVersion": "0.0.1",
    "forceUpdate": false,
    "updateUrl": "https://example.com/download",
    "releaseNotes": "Bug fixes."
  }
}
```

## Cache Strategy
Remote configuration is cached in SharedPreferences under:

`bingietv.remote_config.v1`

Last sync timestamp is stored under:

`bingietv.remote_config.last_sync.v1`

Priority order:
1. Fresh remote config
2. Cached config
3. Built-in defaults

## Fallback Strategy
Invalid JSON, corrupt objects, network errors, missing fields, and unavailable remote sources are handled gracefully.

The app must remain usable when remote config fails. IPTV login, provider switching, playback, favorites, watch history, and existing settings do not depend on remote config.

## UI Integration
Settings now includes:

`Settings -> Remote Configuration`

This page shows:
- Current config source
- Last sync time
- Cache status
- Refresh config button
- Announcement Center
- Maintenance state

Maintenance mode currently shows a banner. It does not enforce blocking yet beyond exposing `allowPlayback` and `allowLogin` for future integration.

## GitHub Provider
`GitHubRemoteConfigProvider` reads a JSON document from:

`BINGIETV_REMOTE_CONFIG_URL`

Pass it at build time with Dart defines, for example:

`--dart-define=BINGIETV_REMOTE_CONFIG_URL=https://raw.githubusercontent.com/org/repo/main/config.json`

No GitHub-specific dependency is required elsewhere in the app.

## Future Provider Support
Add a new provider by implementing `RemoteConfigProvider`.

Expected future providers:
- Cloudflare R2
- AWS S3
- Firebase
- Custom API
- Custom website

Keep provider-specific auth, headers, and URL formats inside provider classes only.

## Migration Notes
- Update info is stored and exposed only.
- Auto-update behavior is Phase 4 and is not implemented here.
- Remote assets are referenced by URL but not downloaded into an asset cache in Phase 3.
