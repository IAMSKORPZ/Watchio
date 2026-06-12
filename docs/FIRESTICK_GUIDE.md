# BingieTV Firestick Guide

## Supported Devices
- Firestick Lite
- Firestick 4K
- Firestick 4K Max
- Fire TV Cube
- Fire TV smart TVs

## Remote Controls
Supported remote actions:
- D-pad up, down, left, right
- Select / OK
- Back
- Play / Pause
- Channel Up / Down where the remote exposes those keys

Playback shortcuts:
- Select: play or pause
- Left: rewind 10 seconds
- Right: fast forward 10 seconds
- Back: exit player
- Channel Up: next live item
- Channel Down: previous live item

## Installation Process
1. Download the BingieTV APK from the configured release source.
2. Enable installation from unknown sources for the downloader/file app.
3. Open the APK.
4. Confirm install.
5. Launch BingieTV from the Fire TV app launcher.

Auto updates do not install silently. BingieTV prompts, downloads the APK, then the user confirms installation.

## TV Launcher Requirements
- APK must include Leanback launcher intent.
- APK must include a TV banner.
- Banner should be `320x180` PNG.
- Current placeholder banner:
  - `android/app/src/main/res/drawable-nodpi/tv_banner.png`

## Performance Notes
- Avoid loading full provider libraries during startup or provider switching.
- Keep poster/logo image sizes bounded.
- Prefer category metadata first, then lazy-load row contents.
- Test on Firestick Lite before increasing image cache sizes or row prefetch counts.

## Known Limitations
- Provider/login text entry uses the Fire TV system keyboard.
- Fire OS remote key mapping can vary by device generation.
- Real-device testing is required before marking Firestick support production-ready.
