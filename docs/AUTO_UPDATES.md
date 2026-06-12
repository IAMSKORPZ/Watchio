# BingieTV Auto Updates

## Architecture
Phase 4 adds GitHub Release update checks without changing IPTV playback, providers, or remote branding architecture.

Core files:
- `lib/services/github_release_service.dart`
- `lib/services/update_service.dart`
- `lib/controllers/update_controller.dart`
- `lib/screens/update/update_screen.dart`
- `lib/widgets/update_available_dialog.dart`
- `lib/widgets/update_startup_check.dart`

Phase 3 `UpdateInfoModel` is reused for `latestVersion`, `minimumVersion`, `forceUpdate`, `updateUrl`, and `releaseNotes`.

## Update Flow
1. App starts and `UpdateStartupCheck` runs a scheduled check in the background.
2. `UpdateController` calls `UpdateService`.
3. `UpdateService` asks `GitHubReleaseService` for the selected channel release.
4. Current app version comes from `package_info_plus`.
5. Versions are compared using semantic version parts.
6. If an update exists, the user sees a prompt.
7. User can open the update screen, download the asset, then manually install.

No silent install is performed.

## GitHub Releases
GitHub releases are read from:

`https://api.github.com/repos/{owner}/{repo}/releases`

Build-time configuration:

```text
--dart-define=BINGIETV_GITHUB_OWNER=your-org
--dart-define=BINGIETV_GITHUB_REPO=your-repo
```

Defaults are the upstream repository names until BingieTV has its own release repository.

## Channel System
Supported channels:
- Stable
- Beta
- Development

Channel mapping:
- Stable: non-prerelease releases without beta/dev markers.
- Beta: prerelease, `beta`, or `rc` releases.
- Development: `dev`, `alpha`, or `nightly` releases.

Selected channel is cached locally.

## Version Comparison
Semantic versions are compared numerically:
- `1.0.0`
- `1.0.1`
- `1.1.0`
- `2.0.0`

Leading `v` and build metadata are ignored for comparison.

## Force Update
`UpdateInfoModel` controls:
- `minimumVersion`
- `forceUpdate`

If `forceUpdate` is true or current version is below minimum version, the update prompt becomes required before continuing.

## Windows Flow
1. User checks updates or startup check finds update.
2. Update screen displays release notes and version.
3. User downloads `.exe` or `.msi` release asset.
4. User opens installer manually.
5. User restarts BingieTV after installer completes.

No forced silent installation is implemented.

## Android And Firestick Flow
1. User checks updates or startup check finds update.
2. Update screen displays release notes and version.
3. User downloads APK release asset.
4. User opens installer manually.
5. Android/Firestick may require Unknown Sources permission.

No silent install is implemented.

## Offline Support
Stored locally:
- Last check time
- Last known version
- Selected update channel
- Cached release metadata

If GitHub is unavailable, cached release metadata is used. If cache is missing, the app continues normally.

## Limitations
- Installer opening depends on platform file handling.
- Download progress is simple loading state only.
- Asset selection prefers `.apk`, `.exe`, and `.msi`.
- Update hosting is GitHub-only in Phase 4.
- No Android TV or Firestick UI optimization is included.
