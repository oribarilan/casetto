# Proposal

## Why

On the phone, Clear Cache gave no clear sign that it worked, the Storage section didn't say how much space downloaded episodes take, and show art still took a moment per show on launch. Measured on the phone, reading art from the cache takes about 12 ms, but shrinking 3000-pixel art to tile size takes 30 to 160 ms per image, one after another, on every launch.

This isn't a roadmap milestone. It adjusts `polish-find-shows`.

## What Changes

- Clear Cache confirms with a checkmark and "Cleared" for a moment.
- The Storage section shows the space downloaded episodes take, as information only. Keep downloaded still decides which stay.
- While art downloads for the first time, its square shows a soft grey shimmer and fades into the art. The tangerine letter square is kept for shows with no art or art that fails, so it no longer flashes before every image.
- Shrunk show art is saved as small files, so later launches read a small file instead of shrinking the original. Clear Cache deletes these too.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `settings`: Clear Cache confirms, and Storage shows the downloads' size.
- `look-and-feel`: how art looks while it downloads, and when there's none.

## Out of scope

- Deleting downloads from Storage, or a size limit for them (see the backlog entry on download space).

## Impact

- `Casterr/Screens/SettingsView.swift`: the confirmation and the downloads row.
- `Casterr/Screens/Theme.swift`: `ArtCache` saves and reads shrunk art files in the caches folder; `ArtworkView` shows the shimmer while downloading.
- `CasterrCore`: the size of a folder, for the downloads row and the cache size.
