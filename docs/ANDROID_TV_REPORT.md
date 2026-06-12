# BingieTV Android TV Report

## TV Launcher Configuration
- Android manifest now declares touchscreen as optional.
- Leanback support is declared optional so the APK can run on phones and TV devices.
- Main activity includes `LEANBACK_LAUNCHER` for Android TV, Google TV, Fire TV, and Firestick launchers.
- Application banner is configured with `@drawable/tv_banner`.
- Placeholder banner files:
  - `assets/tv_banner.png`
  - `android/app/src/main/res/drawable-nodpi/tv_banner.png`

Recommended TV banner size is `320x180` PNG.

## Screens Audited
- Playlist selection
- Xtream home
- M3U home
- Live TV rows
- Movies rows
- Series rows
- Favorites and continue watching rows
- Watch history
- Settings
- Provider Manager
- Remote Configuration
- Updates
- Video player

## Focus Issues Fixed
- Content grid cards now have visible TV focus state with scale, border, and shadow.
- Playlist cards now have visible TV focus state and can be activated with select/enter.
- Provider list items now have visible TV focus state and can switch provider with select/enter.
- Update dialog primary action now autofocuses for remote users.
- Video player now handles TV remote shortcuts:
  - Select / Enter / Play-Pause: play or pause
  - Left: seek back 10 seconds
  - Right: seek forward 10 seconds
  - Back / Escape: exit player
  - Channel Up: next queue item
  - Channel Down: previous queue item

## Remaining Focus Risks
- Text entry for provider/login forms still depends on Android TV or Fire TV system keyboard.
- Popup menus are Flutter defaults; they are focusable, but final behavior should be verified on real Fire OS.
- Some deep overlay controls from `media_kit` are third-party widgets and need device QA.
- Horizontal rows rely on Flutter focus traversal; very large rows should be profiled on hardware.

## Firestick Considerations
- Poster image decode size is capped on content cards to reduce memory pressure.
- No eager loading was added.
- Provider switching remains metadata-first and does not load all channels, movies, or series.
- Update checks still run in background and do not block startup/playback.

## Device QA Needed
- Firestick Lite
- Firestick 4K
- Fire TV Cube
- Chromecast with Google TV
- Android TV emulator

## Build Notes
- Flutter CLI was not available in this environment, so APK/TV emulator validation could not be run here.
