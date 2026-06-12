# BingieTV EPG Architecture

## Goal
Support 500,000+ EPG entries without preloading the full guide.

## Core Files
- `lib/models/epg_models.dart`
- `lib/repositories/epg_repository.dart`

## Models
`EpgChannel`
- provider id
- display name
- optional icon

`EpgProgram`
- channel id
- title
- description
- start/end time
- optional category/icon

`EpgSchedule`
- channel id
- time window
- programs in that window
- cache timestamp

## Repository Contract
`EpgRepository` supports:
- current program lookup
- next program lookup
- channel/time-window schedule lookup
- program upsert
- expired cache cleanup

The app should ask for:
- current program
- next program
- next 24 hours for one channel
- visible time window for a guide row

It must not ask for the full provider EPG.

## Time Window Cache
The first implementation is `InMemoryEpgRepository`.

Cache behavior:
- windows are keyed by channel id + start + end
- cached windows expire by age
- max program count protects memory
- cleanup removes expired entries

Default policy:
- max age: 2 days
- max programs: 50,000

This is an architecture foundation, not the final 500,000 entry store.

## Future Persistent Cache
Future database-backed EPG should store:
- provider id
- channel id
- normalized start time
- normalized end time
- title/description/category

Indexes needed:
- channel id + start time
- channel id + end time
- provider id + channel id

## Import Flow
Future EPG import must:
1. parse XML/JSON in an isolate
2. emit program batches
3. write batches to cache/database
4. cleanup old windows
5. never hold the full EPG document in memory

## Future Isar Points
Do not implement Isar in Phase 7.

The `EpgRepository` interface is the migration boundary. Drift, Isar, or a hybrid cache can implement it later without UI changes.
