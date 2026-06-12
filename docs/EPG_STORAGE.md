# BingieTV EPG Storage

EPG is stored by provider, channel, and time window.

Tables:
- `epg_channels`
- `epg_programs`

Rules:
- Do not preload full XMLTV files.
- Query only visible channel/time windows.
- Index `playlist_id`, `epg_channel_id`, `start_time`, and `end_time`.
