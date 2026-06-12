# BingieTV Phase 1 Feature Audit

## Supported Login Types
| Feature | Status | Notes |
|---|---|---|
| Xtream Codes | Working | Supports server URL, username, password, account info, categories, live, VOD, series. Needs live provider validation. |
| M3U URL | Working | Loads URL, parses M3U, stores items. Large playlists are a risk. |
| M3U File | Working | Uses file picker and parser. Not available on every platform equally. |
| Stalker Portal | Broken | Not implemented. Planned Phase 6. |

## IPTV Features
| Feature | Status | Notes |
|---|---|---|
| EPG | Partial | M3U parser captures TVG fields, but full XMLTV EPG download, storage, matching, and timeline UI are not complete. |
| Live TV | Working | Xtream live and M3U live paths exist. |
| Movies/VOD | Working | Xtream VOD and M3U VOD detection exist. |
| Series | Working | Xtream series and M3U series parsing exist. |
| Watch History | Working | Drift table, service, and UI exist. |
| Continue Watching | Working | Derived from watch history. |
| Favorites | Working | Drift favorites table, repository, controller, and player button exist. |
| Picture in Picture | Partial | `flutter_in_app_pip` dependency exists, but platform validation was not possible. |
| Downloads | Broken | No offline download manager found. |
| Search | Working | Search screen and DB search queries exist. Large data search may be slow. |
| Subtitles | Working | Subtitle settings and player subtitle configuration exist. |
| Background Playback | Partial | Setting and audio service exist. Needs Android lifecycle validation. |
| Chromecast/Casting | Broken | No cast implementation found. |

## Platform Features
| Feature | Status | Notes |
|---|---|---|
| Android | Partial | Runner exists, build not verified due missing Flutter CLI/wrapper script. |
| Windows | Partial | Runner exists, build not verified due missing Flutter CLI. |
| Android TV/Firestick | Partial | No explicit TV manifest support or remote QA. |
| Web | Partial | Runner exists, but M3U file path and media playback behavior need platform testing. |
