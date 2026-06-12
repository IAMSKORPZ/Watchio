# BingieTV Stalker Architecture

Phase 10 adds a Stalker/MAG provider surface without full data import at provider creation.

Core rules:
- Provider type is `IptvProviderType.stalker`.
- Provider-specific fields live in `providerConfig`.
- MAC addresses and tokens are stored only through `SecureStorageService`.
- Portal data is loaded lazily by category/page.
- Stalker EPG IDs map to existing `epgChannelId`.

Flow:
1. Validate portal URL and secure MAC.
2. Handshake.
3. Store token securely.
4. Load profile.
5. Load categories/pages on demand.

Limitations:
- Real portal variations need device QA.
- Full live/VOD/series mapping remains incremental.
- No token or MAC value is written to search indexes, staging tables, telemetry, or logs.
