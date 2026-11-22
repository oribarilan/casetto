# capture Specification

## Purpose
Saves moments while listening, without interrupting playback, and takes them out of the app as Markdown.

## Requirements

### Requirement: Bookmark without pausing
The system SHALL let the listener bookmark the current episode and position with one tap in Now Playing or on the mini player. Playback MUST continue. A bookmark MUST keep the show title, episode title, and audio address.

#### Scenario: Bookmark while playing
- **WHEN** the listener taps the bookmark button at 12:34
- **THEN** a bookmark at 12:34 is saved, playback continues, and a toast says "Bookmarked at 12:34"

#### Scenario: Episode leaves the feed
- **WHEN** a bookmarked episode is no longer in its feed, or the listener unsubscribes from its show
- **THEN** the bookmark still shows its show title, episode title, and position

### Requirement: Optional note
The toast SHALL offer Add Note, which MUST open that bookmark in the Bookmarks tab with its note field ready to type, closing Now Playing if it's open. Tapping the rest of the toast MUST open the bookmark there without the keyboard. The listener SHALL be able to add or edit a bookmark's note in the Bookmarks tab by tapping the note in its row. A bookmark without a note MUST be kept, and its row SHALL say "Add a note".

#### Scenario: Add a note from the toast
- **WHEN** the listener taps Add Note on the toast in Now Playing, types "great point", and taps Done
- **THEN** Now Playing closes, the Bookmarks tab shows that bookmark with the keyboard up in its note, and its note is "great point"

#### Scenario: Edit a note in place
- **WHEN** the listener taps "Add a note" on a bookmark in the Bookmarks tab, types "check this", and taps Done
- **THEN** the bookmark's note is "check this", with no alert or swipe

#### Scenario: Open from the toast
- **WHEN** the listener taps the toast's text instead of Add Note
- **THEN** the Bookmarks tab opens scrolled to that bookmark, with no keyboard

### Requirement: Bookmarks tab
The system SHALL list bookmarks in a Bookmarks tab, grouped by episode with the most recently bookmarked episode first, and each group in position order. Each episode SHALL be one card headed by the show art, the episode title, and the show name. Each bookmark's time SHALL be a play button that plays its episode from the bookmark's position when the episode is still known. The listener SHALL be able to delete a bookmark.

#### Scenario: Play from a bookmark
- **WHEN** the listener taps a bookmark at 12:34
- **THEN** its episode plays from 12:34

#### Scenario: Episode left the feed
- **WHEN** a bookmarked episode is no longer known
- **THEN** its time is grey without a play arrow, and a line under its card says it can't play

### Requirement: Search bookmarks
The Bookmarks tab SHALL filter bookmarks by text in the note, episode title, or show title, ignoring case.

#### Scenario: Search a note
- **WHEN** the listener searches "GREAT" and a bookmark's note is "great point"
- **THEN** that bookmark is listed

### Requirement: Markdown export
The system SHALL share each episode's bookmarks as one Markdown file through the share sheet. The file MUST hold the episode title, show title, audio address, and each bookmark's position and note. An Export All button in the Bookmarks tab SHALL share every listed bookmark as one Markdown file named "Bookmarks.md", with the episodes in the listed order.

#### Scenario: Export an episode
- **WHEN** the listener exports an episode with 2 bookmarks
- **THEN** the share sheet offers one Markdown file named after the show and episode, listing both bookmarks in position order

#### Scenario: Export all
- **WHEN** the listener has bookmarks in 3 episodes and taps Export All
- **THEN** the share sheet offers "Bookmarks.md" with all 3 episodes

#### Scenario: Export all while searching
- **WHEN** a search lists 1 of 3 episodes and the listener taps Export All
- **THEN** the file holds only the listed episode
