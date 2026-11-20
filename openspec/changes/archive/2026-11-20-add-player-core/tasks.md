# Tasks

## 1. Project setup

- [x] 1.1 Create the `CasterrCore` local Swift package (iOS 27 and macOS 27 platforms, Swift Testing) with one placeholder test, and verify `swift test` passes
- [x] 1.2 Add `project.yml` for the Casterr iOS app target (iOS 27 only, depends on `CasterrCore`, background audio mode on), gitignore the generated `.xcodeproj`, and verify `xcodegen generate` and an `xcodebuild` simulator build both succeed
- [x] 1.3 Add the FeedKit dependency (MIT) to `CasterrCore`, and verify the package still builds and tests pass
- [x] 1.4 Add build and test commands to the README (`brew install xcodegen`, `xcodegen generate`, `swift test`, `xcodebuild test`), and verify each command runs as written

## 2. Domain types

- [x] 2.1 Implement `ShowKey` from the normalized feed URL (https, lowercase host, no trailing slash), and verify unit tests cover each normalization case
- [x] 2.2 Implement `EpisodeKey` (show key plus GUID, otherwise plus audio URL), and verify unit tests cover both forms and a missing GUID
- [x] 2.3 Implement the `Place` enum (`queue`, `archive(reason: played)`, none) and its flat stored form, and verify round-trip tests, including that invalid stored combinations are rejected
- [x] 2.4 Implement the effective speed function (show override, otherwise global, clamped to 1.0 to 2.0 in 0.1 steps), and verify unit tests cover override, no override, global change, and reset
- [x] 2.5 Implement the played rule (fewer than 60 seconds remaining), and verify unit tests at 61 seconds, 60 seconds, 59 seconds, and with an unknown duration

## 3. Persistence

- [x] 3.1 Define the feed-cache SwiftData models (`ShowRecord`, `EpisodeRecord`, unique on key) in their own `ModelConfiguration`, and verify an in-memory store test inserts and fetches a show with episodes
- [x] 3.2 Define the user-data SwiftData models (`Subscription`, `EpisodeState`, `Settings`) following the CloudKit rules (no unique attributes, every property optional or defaulted, no relationships), and verify a test that asserts these rules on the schema
- [x] 3.3 Implement the subscription store with a key lookup before insert, and verify a test that subscribing twice leaves one record
- [x] 3.4 Implement the Queue store on episode states (place `queue` plus `queuePosition` 1 to N, rewritten on every change) (append, move, move to top, remove), and verify tests for every queue spec scenario
- [x] 3.5 Implement the episode-state store (place, progress, mark played, mark unplayed, played episode leaves the Queue), and verify tests for the one-place-per-episode and played-episode spec scenarios
- [x] 3.6 Implement the settings store (`global` record, default speed 1.0x), and verify tests for the default and an update
- [x] 3.7 Wire both configurations into one `ModelContainer` with a long-lived writer `@ModelActor` that returns value types only, and verify a test that wipes the feed cache, re-fetches from fixtures, and keeps all user data pointing to the right episodes

## 4. Feeds and OPML

- [x] 4.1 Add fixture feeds (normal, no GUIDs, `itunes:new-feed-url`, not a podcast, malformed) to the test resources, and verify the fixture files load in a test
- [x] 4.2 Implement feed parsing with FeedKit into value types (show metadata, episodes, new feed URL), and verify parsing tests against every fixture, including the error for a non-podcast feed
- [x] 4.3 Implement OPML parsing with `XMLParser`, and verify tests for a valid file, a file with bad entries, and a file that is not OPML
- [x] 4.4 Implement the feed fetcher (full GET, last success and last error recorded per feed), and verify tests with a stubbed `URLProtocol` for the success and error paths
- [x] 4.5 Implement subscribe by URL (fetch, parse, already-subscribed check, newest-first episodes, no Queue change), and verify tests for every "Subscribe by RSS URL" and "New subscription places no episodes" scenario
- [x] 4.6 Implement OPML import (per-feed results, failures with reasons, skip already-followed shows), and verify tests for every OPML spec scenario
- [x] 4.7 Implement refresh-all (`TaskGroup` capped at 6, failures isolated, feed moves applied without changing the show key), and verify tests for one failing feed and a feed that moves
- [x] 4.8 Implement unsubscribe (subscription removed, queued episodes kept, feed no longer refreshed), and verify tests for both unsubscribe scenarios

## 5. Playback

- [x] 5.1 Implement the `AudioEngine` protocol and its `AVPlayer` implementation (play, pause, seek, rate, `.timeDomain`, time updates, `.playback` and `.spokenAudio` session), and verify an episode streams on the simulator from its saved position at 1x and 2x
- [x] 5.2 Implement the player controller (plays Queue item 1, moves a played episode to the archive and starts the next one, saves progress every 5 seconds and on pause, interruption, and background), and verify tests with a fake `AudioEngine` for the played, next-episode, and progress scenarios
- [ ] 5.3 Handle interruptions and route changes (pause during a call, resume when the system says to, pause when headphones disconnect), and verify on a device against the background-audio spec scenarios → Tracked in `openspec/device-checks.md`.
- [ ] 5.4 Integrate system controls with the Now Playing framework (`MediaSession`): metadata, play, pause, skip 30 seconds forward and 15 back, seek. Verify the lock screen, Control Center, and headphone scenarios on a device. Switch to the MediaPlayer APIs only if a scenario is blocked, and record why in design.md → Tracked in `openspec/device-checks.md`.
- [x] 5.5 Implement the sleep timer (fixed duration, end of episode, cancel), and verify tests with a fake clock for all three scenarios
- [x] 5.6 Handle playback errors (offline, failing audio URL) with a message and no Queue change, and verify tests with a fake `AudioEngine` that fails

## 6. Screens

- [x] 6.1 Build the Queue home screen (Now Playing first, drag to reorder, swipe to remove, empty state linking to shows), and verify by hand on the simulator against the "Queue is the home screen" and "Manage Queue order" scenarios → Covered by the screens UI test (drag to reorder, swipe to remove, empty state).
- [x] 6.2 Build the show list, plus the add-by-URL sheet with its error messages, and verify by hand that each "Subscribe by RSS URL" scenario shows the right result
- [ ] 6.3 Build the OPML import flow (file picker, then a report sheet listing failed feeds and reasons), and verify by hand with the fixture OPML files → Tracked in `openspec/device-checks.md`.
- [x] 6.4 Build the show page (episodes newest first, play, add to Queue, mark played or unplayed, unsubscribe, last-refresh status, pull to refresh), and verify by hand against the related scenarios
- [x] 6.5 Mock up 2 or 3 options for setting the global speed and the per-show speed override (Now Playing, show page, or both), and verify that the user picked one and that the choice is recorded in design.md
- [x] 6.6 Build Now Playing (play and pause, skip, scrubber, speed control as chosen in 6.5, sleep timer), and verify by hand against the speed, skip, and sleep timer scenarios
- [x] 6.7 Add an XCTest smoke test that launches the app, adds a fixture feed, queues an episode, and checks the Queue. Add the `xcodebuild test` command to the README, and verify that it passes on the simulator

## 7. Integration check

- [ ] 7.1 On a real device, import a real OPML export with 20+ shows, queue 5 episodes, listen with the phone locked, take a call, force-quit, and reopen. Verify that every M1 spec scenario holds, and list any failures as new tasks → Tracked in `openspec/device-checks.md`.

## Workflow follow-up

- Archive the change with `openspec archive add-player-core` after the user approves the results.
- Start M2 (Inbox and triage) as a new change.
