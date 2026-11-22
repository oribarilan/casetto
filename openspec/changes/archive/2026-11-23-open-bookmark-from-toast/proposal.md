# Proposal

## Why

On the phone, Add Note on the bookmark toast turned the toast into a text field over Now Playing, and the keyboard pushed it partly off the top of the screen. Even working well, a note field over Now Playing feels out of place: notes live in Bookmarks.

This isn't a roadmap milestone. It adjusts capture from M6.

## What Changes

- Add Note on the toast closes Now Playing if it's open, switches to the Bookmarks tab, scrolls to that bookmark, and puts the keyboard in its note, as if the listener had gone there and tapped it.
- Tapping the rest of the toast opens the same bookmark without the keyboard.
- The toast no longer holds a text field.
- The backlog entry "Bookmark toast and Add Note" is removed.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `capture`: where Add Note and a tap on the toast take the listener.

## Out of scope

- The toast's look, its 4 seconds, and the bookmark button.
- Notes on other screens.

## Impact

- `Casterr/Screens/BookmarksView.swift`: the toast becomes two taps that ask the app to open a bookmark; the Bookmarks tab scrolls to it and focuses its note.
- `Casterr/AppModel.swift`: a request to open a bookmark, which `RootView` answers by closing Now Playing and switching tabs.
- `CasterrUITests`: `testCapture` adds the note through the Bookmarks tab from the toast.
