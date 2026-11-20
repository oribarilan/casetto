# Design

## Context

The repo has no code. The local toolchain is Xcode 27.2, Swift 6.4.2, and the iOS 27.1 simulator. XcodeGen is installed. Product decisions come from `podcast_app_concept.md`. Requirements are in this change's specs. The constraints that shape the approach:

- Feed data and user data stay apart, and only user data will sync (M8).
- User data must already follow the CloudKit rules, so M8 needs no migration.
- The developer works 5 to 10 hours a week. Fast tests and a small surface matter more than architecture.

## Goals / Non-Goals

**Goals:**
- The domain rules (identity, places, Queue order, the played rule, settings resolution) live in a package that tests on macOS in seconds, without a simulator.
- The user-data schema is CloudKit-compatible from the first commit.
- Playback is built on standard AVFoundation, so skip silences and voice boost can later replace the audio path without touching the domain.

**Non-Goals:**
- A general app architecture framework (TCA, VIPER, coordinators).
- Offline playback (M3).
- Any abstraction for features after M1.

## Decisions

### D1. Project layout: XcodeGen app plus a local `CasterrCore` package

`project.yml` defines the app target. The generated `.xcodeproj` is gitignored. A local Swift package, `CasterrCore`, holds the domain types, feed and OPML parsing, and the stores. The app target holds the SwiftUI views and playback (AVFoundation and MediaPlayer).

- Why: `project.yml` is short text that people and agents can edit, review, and diff. A `.pbxproj` is none of those. With the package split, `swift test` runs the domain tests on macOS in seconds.
- Alternatives:
  - A project created by hand in Xcode, using synchronized folders. It needs no tool, but agents can't safely create or edit the `.pbxproj`.
  - Tuist. It's more capable than M1 needs, and it isn't installed.
- Cost: contributors need `brew install xcodegen`. The README will say so.

### D2. Two SwiftData stores: a feed cache and user data

The app opens one `ModelContainer` with two `ModelConfiguration`s, each with its own store file:

- **Feed cache** (`ShowRecord`, `EpisodeRecord`) stays on the device. It may use unique attributes and relationships, and the app can delete it and re-fetch. It never syncs.
- **User data** (`Subscription`, `EpisodeState`, `Settings`) follows the CloudKit model rules now: no unique attributes, every property optional or defaulted, and no relationships. Records point to shows and episodes by key strings. M8 turns on CloudKit for this configuration only.

One `Library` actor in `CasterrCore` owns both stores and returns value types only. Views and playback never touch `ModelContext` directly. A protocol gets added only when a second implementation exists.

- Why: a separate configuration is how SwiftData syncs part of a schema. Keeping relationships out of user data removes the hardest CloudKit rule, and the split already exists in the concept.
- Alternatives:
  - One store with CloudKit rules everywhere. That syncs thousands of episode records for no benefit.
  - GRDB/SQLite. It's mature, but it adds a dependency and gives up the built-in CloudKit path.
- Without unique constraints, the user-data store prevents duplicates itself by looking up a key before inserting. Sync can still create duplicates across devices, so M8 adds merging by key on read. M1 doesn't need it.

### D3. Stable keys as value types

`ShowKey` and `EpisodeKey` are string-backed value types made by validating constructors.

- **ShowKey** is the normalized feed URL at the moment you subscribe, and it never changes. Normalizing means: https scheme, a lowercase host, and no trailing slash. A Subscription keeps its current feed URL separately. When `itunes:new-feed-url` moves the feed, only that URL changes and the key stays the same.
- We considered preferring `podcast:guid` when a feed has one. We dropped it because most feeds don't have one, and the URL key already survives moves.
- **EpisodeKey** is the ShowKey plus the item's GUID, otherwise the ShowKey plus the audio URL.
- Why: if the key were derived from the current URL, it would change when the feed moves and orphan all user data.
- Alternative: an app-generated UUID per show. It's stable, but two devices that subscribe separately would create different UUIDs for the same show, and M8 would duplicate it.

### D4. Episode place as one enum

`EpisodeState` stores `place` (`queue` or `archive`) and an `archiveReason` (`played` in M1), next to `progressSeconds`. An episode with no `EpisodeState`, or with progress but no place, has no place. The domain exposes `Place` as a Swift enum with an associated reason, so invalid combinations can't be expressed. The stored form is flat because the CloudKit rules require it.

- Alternative: separate `inQueue` and `archived` flags. That allows "queued and archived", which the spec forbids.
- M2 adds `inbox` and more archive reasons to the same enum.

### D5. Queue order as integer positions

The Queue is the `EpisodeState` records whose place is `queue`, sorted by `queuePosition: Int`, from 1 to N. There is no separate Queue record, so place and position can't disagree. Every change (add, move, remove, play) rewrites the positions of the whole Queue. Now Playing is position 1.

- Why: it's the simplest correct option. A Queue holds about 20 items, so rewriting them all costs nothing.
- Alternative: fractional sort keys, where a reorder writes one record and syncing devices conflict less. We rejected it as too complex for M1. If sync conflicts show up in practice, M8 can revisit it.

### D6. Feed parsing with FeedKit; OPML with `XMLParser`

FeedKit (MIT license, release 10.10.2 from Oct 2026, actively maintained) parses RSS with the iTunes and Podcast namespaces. OPML is a single element type, so a few lines of Foundation's `XMLParser` handle it with no dependency.

- Alternative: a hand-written `XMLParser` for RSS. Real-world feeds are messy, and FeedKit has already absorbed that.

### D7. Refresh: full fetch, limited concurrency, background writes

Refresh runs on foreground and on pull to refresh.
- It uses a `TaskGroup` capped at 6 concurrent fetches.
- It always fetches and parses the full feed.
- Parsing runs off the main actor, and a `@ModelActor` writes in batches.
- Each feed records its last success and its last error.
- Conditional GET (ETag and Last-Modified) was dropped for simplicity. Add it only if refresh feels slow.

### D8. Playback: one `AVPlayer`, with the Queue owned by the domain

The app uses a single `AVPlayer`, not an `AVQueuePlayer`. The domain owns order and decides what plays next.
- `AVAudioSession` uses category `.playback` and mode `.spokenAudio`.
- Speed sets `rate`. `audioTimePitchAlgorithm` is `.timeDomain`, which Apple describes as suited to voice and which is already the playback default. The app still sets it explicitly.
- The lock screen, Control Center, and headphones go through the iOS 27 Now Playing framework (`MediaSession`). Apple says not to mix it with `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter` for local playback. The app targets iOS 27 only, so it uses the new framework alone.
  - Alternative: the MediaPlayer APIs. They're older, aren't deprecated, and have far more example code. Pick them if the new framework blocks a spec scenario during the playback task.
- A periodic time observer does two jobs. It saves progress every 5 seconds, and also on pause, on interruption, and when the app goes to the background. It also checks the played rule: fewer than 60 seconds remaining.
- The sleep timer belongs to the player controller and is not persisted.

- Why: `AVQueuePlayer` keeps its own copy of the order, which drifts from the Queue the user sees.
- The audio path sits behind a small `AudioEngine` protocol (play, pause, seek, rate, time updates), so the player controller can be tested with a fake.
- Skip intervals are fixed constants: 30 seconds forward, 15 back.

### D9. Settings resolution

`Settings` is a single user-data record with the fixed id `global`. It holds only `speed`, which defaults to 1.0 and ranges from 1.0 to 2.0. `Subscription.speedOverride` is an optional `Double`, where nil means "follow global". The effective speed is a pure function in `CasterrCore`: the override if present, otherwise the global value.

### D10. UI state

The app uses SwiftUI with `@Observable` view models. It has four screens:
- Queue (home)
- Show list
- Show page
- Now Playing

It has two sheets: add-by-URL and the OPML import report. Navigation is a `NavigationStack`. There's no tab bar until M2 adds the Inbox.

### D11. Tests

- Swift Testing in `CasterrCore` covers keys and normalization, places, Queue ordering, the played rule, settings resolution, and feed and OPML parsing against saved fixture files.
- The stores are tested with in-memory SwiftData configurations.
- The app target gets a thin XCTest smoke test on the simulator.
- Playback is checked by hand against a short checklist, because AVFoundation behavior under interruptions isn't worth mocking.

### D12. Speed controls (decided with mockups, task 6.5)

The speed button in Now Playing opens a sheet with a 1.0x to 2.0x slider and a "This show / All shows" switch. "This show" sets the show's override. "All shows" sets the global speed and clears this show's override, so the change is heard right away. The show page lists an active override with a Reset button.

### D13. Interruptions on iOS 27

iOS 27 deprecates the interruption notification's type and options. The app pauses on `AVAudioSession.didBecomeInactiveNotification` when the deactivation source is the system, and resumes on `resumptionRecommendationNotification` when the recommendation is `shouldResume`. Headphone disconnects still use the route change notification (`oldDeviceUnavailable`).

## Risks / Trade-offs

- [The Now Playing framework is new, so there's little example code] → Playback is checked by hand on a device early. The MediaPlayer APIs remain the fallback (D8).
- [SwiftData performance with about 10k episodes and bulk refresh writes] → Writes run in a background actor in batches. If it struggles, the store protocols let the feed cache move to SQLite alone.
- [SwiftData models crash if their `ModelActor` is released while still in use] → The writer actor lives as long as the app. Data crosses actor boundaries as value types, never as model objects.
- [No unique constraints in user data allows duplicate records] → The store looks up keys before inserting, with a test. Merging across devices waits for M8.
- [Feeds that lie: missing GUIDs, changing audio URLs, wrong durations] → The audio URL is the fallback key. Fixture tests use real problem feeds. Duration comes from the player once known.
- [Audio servers without range-request support, or with redirect chains] → AVPlayer handles most cases. A failure shows "could not be played" and leaves the Queue alone.
- [XcodeGen is an extra tool for contributors] → One line in the README. `project.yml` is the only project source.

## Migration Plan

None. This is the first release. The user-data schema is built so that M8 can turn on CloudKit without migrating data.

## Open Questions

- Assumption to confirm: "mark unplayed" resets progress and clears the place.
