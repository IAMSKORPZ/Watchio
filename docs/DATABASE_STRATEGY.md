# BingieTV Database Strategy

Phase 8 keeps Drift and SQLite as the source of truth.

- Use paged queries for content.
- Use indexes for playlist, category, name, and EPG windows.
- Use transactions for import commits and recovery markers.
- Keep provider secrets out of tables and indexes.

Schema additions that do not need generated Drift classes are created with raw SQL so rollout stays small.
