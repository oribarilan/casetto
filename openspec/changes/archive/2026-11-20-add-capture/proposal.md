# Proposal

## Why

Podcasts are full of moments worth keeping, and today the only way to keep one is to stop and write it down somewhere else. This change is roadmap milestone **M6: Capture**: one tap saves the moment without pausing, a note is optional, and the moments leave the app as Markdown.

## What Changes

- A **bookmark button** in Now Playing and on the mini player. One tap saves the episode and position and keeps playing.
- A **toast** confirms the bookmark and offers **Add Note**.
- A **Bookmarks tab**, the third tab, with bookmarks grouped by episode, newest first. Tapping one plays the episode from that moment. Notes can be edited and bookmarks deleted.
- **Search** across notes, episode titles, and show titles.
- **Markdown export**: each episode's bookmarks share as one Markdown file through the share sheet.
- A bookmark keeps a **snapshot** of the show title, episode title, and audio address, so it survives the episode leaving the feed and unsubscribing.

## Capabilities

### New Capabilities

- `capture`: bookmarks, notes, search, and Markdown export.

### Modified Capabilities

None.

## Out of scope

- A bookmark button on the lock screen.
- Clips, transcripts, and exporting every episode at once.
- Playing a bookmark whose episode is no longer in the feed cache. Its row stays, without playback.

## Impact

- `CasterrCore`: a `Bookmark` model in the synced user store (CloudKit rules), `Library` operations, and a Markdown renderer.
- App: the bookmark buttons, the toast, the Bookmarks tab, and a share item per episode.
- No new dependencies.
