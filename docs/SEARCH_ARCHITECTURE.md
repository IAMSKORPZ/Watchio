# BingieTV Search Architecture

Search order:

1. FTS5 table `content_search_fts`
2. Indexed name queries
3. LIKE fallback

Search uses a 50-result cap by default. UI search remains debounced at 300 ms. Results are paged and never require loading a full provider library into memory.
