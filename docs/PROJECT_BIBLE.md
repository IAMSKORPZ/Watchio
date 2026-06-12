# BingieTV Project Bible

# Part 1 of 3

# Global Rules + Phase 1 -> Phase 5

---

# Project Overview

BingieTV is a commercial-grade IPTV platform supporting:

- Xtream Codes
- M3U URL
- M3U File
- Stalker Portal
- Android
- Android TV
- Firestick
- Windows

The project is designed for providers containing:

```text
~10,000 Live Channels
~28,000 Movies
~12,000 TV Shows
```

The architecture must remain:

```text
Modular
Scalable
Provider Agnostic
TV Friendly
Cloud Ready
Secure
```

---

# Global Rules

## Architecture Rules

Always:

```text
Repository Pattern
Service Layer Pattern
Provider Abstractions
Dependency Injection
Feature Isolation
```

Never:

```text
Hardcode Providers
Hardcode Backend Services
Create Circular Dependencies
Mix UI With Business Logic
```

---

# Security Rules

Never store:

```text
Passwords
Tokens
MAC Addresses
Refresh Tokens
```

inside:

```text
SharedPreferences
Backups
Logs
Analytics
Exports
```

Sensitive data must use:

```text
SecureStorageService
```

---

# Performance Rules

The application must support:

```text
10000+ Live Channels
28000+ Movies
12000+ Series
```

Never:

```text
Load Entire Provider Into Memory
Load Entire EPG Into Memory
Perform Blocking UI Operations
```

Always:

```text
Pagination
Lazy Loading
Caching
Streaming Imports
Batch Database Writes
```

---

# Database Rules

Use:

```text
SQLite (Drift)
FTS5 Search
Indexed Queries
Transactions
```

Avoid:

```text
Large Full Table Scans
Duplicate Data Storage
Schema Changes Without Need
```

---

# UI Rules

Support:

```text
Touch
Mouse
Keyboard
TV Remote
Firestick Remote
```

Every feature must remain TV-safe.

---

# Phase 1

# BingieTV Rebrand & Foundation

## Goal

Transform ClubTVI into BingieTV.

---

## Files Modified

```text
android/*
windows/*
web/*
ios/*
macos/*
pubspec.yaml
main.dart
```

---

## Requirements

Replace:

```text
ClubTVI
SkorpzTV
```

with:

```text
BingieTV
```

---

## Branding

Update:

```text
App Name
Package Name
Window Title
About Screens
Metadata
```

---

## Documentation

Create:

```text
docs/ARCHITECTURE.md
docs/BUILD_STATUS.md
docs/FEATURE_AUDIT.md
docs/PERFORMANCE_AUDIT.md
docs/BINGIETV_ROADMAP.md
```

---

## Output

Provide:

```text
Files Created
Files Modified
Branding Changes
Known Build Issues
Recommended Phase 2 Tasks
```

---

# Phase 2

# Provider Manager

## Goal

Support multiple IPTV providers.

---

## New Files

```text
provider_model.dart
provider_repository.dart
provider_controller.dart
provider_list_screen.dart
provider_form_screen.dart
```

---

## Provider Types

Support:

```text
Xtream
M3U URL
M3U File
```

---

## Provider Status

Track:

```text
Online
Offline
AuthFailed
Unknown
```

---

## Features

Support:

```text
Create Provider
Edit Provider
Delete Provider
Enable
Disable
Default Provider
Provider Switching
```

---

## Validation

Validate:

```text
Xtream Credentials
M3U URLs
Playlist Integrity
```

before saving.

---

## Storage

Store provider metadata locally.

No secure credential system yet.

---

## Output

Provide:

```text
Files Created
Files Modified
Provider Features Added
Known Limitations
Recommended Phase 3 Tasks
```

---

# Phase 3

# Remote Branding System

## Goal

Allow branding updates without rebuilding.

---

## New Files

```text
branding_model.dart
theme_model.dart
announcement_model.dart
maintenance_model.dart
update_info_model.dart

remote_config_provider.dart
github_remote_config_provider.dart

remote_config_service.dart
branding_service.dart

branding_controller.dart
```

---

## Remote Config

Support:

```text
Theme
Logo
Banner
Maintenance Notices
Announcements
Update Information
```

---

## Hosting

Primary Source:

```text
GitHub Repository
```

Fallback:

```text
Local Cache
Built-In Defaults
```

---

## Startup Flow

```text
Launch
|
v
Load Defaults
|
v
Load Cache
|
v
Fetch Remote Config
|
v
Apply Updates
```

---

## Requirements

Invalid remote data must never:

```text
Crash App
Block Startup
Prevent Playback
```

---

## Output

Provide:

```text
Files Created
Files Modified
Remote Features Added
Cache Strategy
Known Limitations
Recommended Phase 4 Tasks
```

---

# Phase 4

# Auto Updates

## Goal

Allow BingieTV to update through GitHub Releases.

---

## New Files

```text
update_service.dart
github_release_service.dart
update_controller.dart

update_screen.dart

update_available_dialog.dart
update_startup_check.dart
```

---

## Update Channels

Support:

```text
Stable
Beta
Development
```

---

## Features

Support:

```text
Manual Check
Startup Check
Scheduled Check
Force Updates
```

---

## Sources

Use:

```text
GitHub Releases
```

---

## Download Support

Support:

```text
APK
EXE
MSI
```

---

## Rules

Do not:

```text
Perform Silent Installs
Install Without Consent
```

User must approve.

---

## Output

Provide:

```text
Files Created
Files Modified
Update Features Added
Known Limitations
Recommended Phase 5 Tasks
```

---

# Phase 5

# Android TV & Firestick Support

## Goal

Create a TV-first experience.

---

## New Files

```text
tv_focusable.dart

ANDROID_TV_REPORT.md
FIRESTICK_GUIDE.md
```

---

## Android TV

Support:

```text
Leanback Launcher
TV Banner
Remote Navigation
Focus Traversal
```

---

## Firestick

Support:

```text
D-Pad Navigation
Focus Highlighting
Fast Scrolling
Low Memory Devices
```

---

## Player Controls

Remote Support:

```text
Play
Pause
Seek
Back
Channel Up
Channel Down
```

---

## Focus Rules

All interactive controls must support:

```text
Remote Focus
Keyboard Focus
Mouse Focus
```

---

## Performance

Optimize:

```text
Poster Decoding
Image Memory Usage
Focus Rendering
```

for:

```text
Firestick Lite
Firestick 4K
Android TV
```

---

## Output

Provide:

```text
Files Created
Files Modified
TV Features Added
Firestick Improvements
Known Limitations
Recommended Phase 6 Tasks
```

---

# End Of Part 1

Next:

```text
Part 2
Phase 6 -> Phase 10
```

---

# Part 2 of 3

# Phase 6 -> Phase 10

---

# Phase 6

# Large Provider Optimization

## Goal

Support extremely large IPTV providers without memory issues.

Target scale:

```text
~10,000 Live Channels
~28,000 Movies
~12,000 TV Shows
```

## New Files

```text
paged_result.dart
performance_service.dart
cache_policy_service.dart
LARGE_PROVIDER_REPORT.md
PERFORMANCE_STRATEGY.md
```

## Requirements

Never load entire live, movie, or series libraries into memory.

## Pagination

Implement page size 60, infinite scrolling, and lazy loading for live TV, movies, series, and search results.

## Search

Support debounced search, result limits, and incremental results with a 300 ms debounce and 50-result cap.

## Cache Management

Create cleanup policies for search cache, provider cache, and category cache.

## Performance Metrics

Track startup time, category load time, provider switch time, and search time.

---

# Phase 7

# Streaming Import Architecture

## Goal

Prevent memory crashes during provider imports.

## New Files

```text
import_progress_model.dart
import_session_model.dart
streaming_json_array_decoder.dart
streaming_m3u_import_service.dart
xtream_streaming_import_service.dart
IMPORT_ARCHITECTURE.md
EPG_ARCHITECTURE.md
```

## Requirements

Xtream imports must stream HTTP responses, parse JSON incrementally, write 500-item batches, and avoid full memory loads.

M3U imports must read line by line, parse incrementally, and write directly to the database.

Import recovery must support cancellation, resume, failure recovery, and cleanup of partial imports.

Progress reporting must track items imported, lines processed, percentage, and elapsed time.

EPG preparation must model channels, programs, and schedules without preloading the full EPG.

---

# Phase 8

# Database, Search & EPG Persistence

## Goal

Create a scalable storage layer.

## New Files

```text
search_repository.dart
import_recovery_service.dart
DATABASE_STRATEGY.md
SEARCH_ARCHITECTURE.md
EPG_STORAGE.md
```

## Requirements

Use SQLite, Drift, indexes, and transactions.

Persist EPG channels, programs, and schedule windows in SQLite. Never keep full EPG in memory.

Search priority is FTS5, indexed fallback search, then LIKE fallback search.

Track active, completed, and failed imports with resume, rollback, and recovery.

Optimize indexes for playlist_id, category_id, name, epg_channel_id, start_time, and end_time.

---

# Phase 9

# Benchmark Framework

## Goal

Create performance measurement infrastructure.

## New Files

```text
benchmark_result_model.dart
benchmark_service.dart
BENCHMARK_RESULTS.md
PRODUCTION_READINESS.md
ISAR_EVALUATION.md
OPTIMIZATION_BACKLOG.md
```

## Requirements

Do not fabricate benchmark numbers. Use `PENDING REAL DEVICE TESTING` until actual testing occurs.

Measure startup, search, import, EPG lookup, and provider switch. Support JSON export.

Prepare hooks for FPS, memory usage, frame drops, and image decoding on Firestick-class devices.

Evaluate Isar migration, Drift scalability, and storage costs.

---

# Phase 10

# Stalker Portal Support

## Goal

Add support for Stalker / MAG providers.

## New Files

```text
stalker_provider_config.dart
stalker_auth_service.dart
stalker_api_service.dart
stalker_import_service.dart
stalker_repository.dart
STALKER_ARCHITECTURE.md
```

## Provider Types

Add `IptvProviderType.stalker`.

## Configuration

Support portal URL, MAC address, device ID, serial number, and user agent override. Store provider-specific configuration inside `providerConfig` and avoid model bloat.

## Authentication

Flow: handshake, acquire token, load profile, validate access.

## Token Handling

Support token refresh, session recovery, and silent re-authentication.

## Imports

Use lazy loading, category staging, and incremental loading. Do not import full portal data at provider creation.

## Search And EPG Integration

Map Stalker data into existing live, movie, and series models so FTS search, pagination, and filtering continue working.

Map `epg_id` to `epgChannelId`.

## Security

Never store tokens or MAC addresses in search indexes, import staging tables, telemetry, or logs.

---

# End Of Part 2

Next:

```text
Part 3
Phase 11 -> Phase 15
```
