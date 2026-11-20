# Proposal

## Why

Casterr has no code yet. The triage bet (M2 onward) needs a player that can subscribe to shows, play episodes reliably, and keep a Queue you trust. This change is roadmap milestone **M1: Player core**. It also lays down the data model every later milestone builds on: feed data apart from user data, stable feed keys, and exactly one place per episode.

## What Changes

- New Xcode project for an iOS app in SwiftUI, targeting the latest major iOS only.
- Subscribe to a show by pasting an RSS URL, or by importing an OPML file. Unsubscribe from a show.
- Parse feeds into Shows and Episodes, identified by stable feed keys. Refresh every feed when the app opens, and on pull to refresh.
- A show page that lists its episodes. From it you can play an episode or add it to the Queue.
- A manual Queue that is also the home screen. Item #1 is always Now Playing. You can add, remove, and reorder items.
- Streaming playback with background audio, lock screen and Control Center controls, a sleep timer, and saved progress.
- Playback speed from 1x to 2x with natural pitch. Speed has a global default, and each show can override it.
- Skip forward 30 seconds and skip back 15 seconds.
- An episode counts as played when fewer than 60 seconds remain, or when you mark it played. It then moves to the archive and leaves the Queue.

## Capabilities

### New Capabilities

- `subscriptions`: following shows. Adding by RSS URL or OPML, unsubscribing, refreshing feeds, and the identity of shows and episodes.
- `queue`: the ordered list of episodes you chose to hear. It covers where an episode lives (Queue, archive, or none) and what "played" means.
- `playback`: playing audio. Streaming, background audio, system controls, speed, skip intervals, sleep timer, and progress.

### Modified Capabilities

None. This is the first change.

## Out of scope

These are left for later milestones:
- The Inbox, triage levels, expiry, play next, filters, the event log, and undo (M2).
- Downloads and background refresh (M3).
- Rule cards (M4).
- Search, Apple charts, and onboarding (M5).
- Bookmarks (M6).
- OPML export (M7).
- CloudKit sync (M8).
- Skip silences and voice boost, which come after the MVP.

M1 adds no fields or types for any of these.

## Impact

- New Xcode project, app target, and unit test target.
- Frameworks: SwiftUI, SwiftData, AVFoundation, MediaPlayer.
- Feed parsing: one RSS/XML dependency, or Foundation's `XMLParser`. The design decides which.
- Network: publisher feeds and publisher audio hosts only.
