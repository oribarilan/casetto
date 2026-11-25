# Proposal

## Why

Several controls feel laggy because they show a tap only after the whole app reacts to it. The save bumps the counter that reloads every open screen, downloads are checked, the screen reads its data again, and only then does the control show its new value. The save itself is usually one field. The listener noticed it most in the new episodes sheet, on Follow and Star, and in Settings.

This is a backlog fix, not a numbered roadmap milestone.

## What Changes

Each control shows the tap at once and saves in the background. The rest of the app updates a moment later, as it does now.

- **New episodes sheet:** the level tiles, "Use my default", and the day picker.
- **Star**, on the show page and in Find Shows. Find Shows no longer dims the row's buttons while it saves.
- **Follow**, on the show page and in Find Shows: the button shows Following at once while the feed downloads. If the download fails, it goes back to Follow and shows the error, as today.
- **Settings:** Remove unplayed episodes after, Keep downloaded, and Default speed. Voice boost and the button pickers already work this way.
- The backlog entries for the new episodes settings lag and the Follow lag go.

## Out of scope

- Making the app-wide reload after every change cheaper.
- Downloading a huge feed faster. Follow only stops making you wait for it.
- Now Playing's speed and voice boost sheets, which already work this way.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. The behavior in the specs doesn't change; it shows sooner. A failed Follow already shows its error.

## Impact

- `Casterr/Screens/NewEpisodesSheet.swift`: `@State` copies of the level and the override.
- `Casterr/Screens/ShowView.swift` and `DiscoverView.swift`: Follow and Star show the new state before the save finishes, and roll back on error.
- `Casterr/Screens/SettingsView.swift`: the three pickers set their value before saving.
- `CHANGELOG.md` and `project.yml`: version 0.4.1, a fix.
