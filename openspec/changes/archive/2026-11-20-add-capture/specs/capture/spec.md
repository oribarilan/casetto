# Spec Delta

## Purpose

Saves moments while listening, without interrupting playback, and takes them out of the app as Markdown.

## ADDED Requirements

### Requirement: Bookmark without pausing
The system SHALL let the listener bookmark the current episode and position with one tap in Now Playing or on the mini player. Playback MUST continue. A bookmark MUST keep the show title, episode title, and audio address.

#### Scenario: Bookmark while playing
- **WHEN** the listener taps the bookmark button at 12:34
- **THEN** a bookmark at 12:34 is saved, playback continues, and a toast says "Bookmarked at 12:34"

#### Scenario: Episode leaves the feed
- **WHEN** a bookmarked episode is no longer in its feed, or the listener unsubscribes from its show
- **THEN** the bookmark still shows its show title, episode title, and position

### Requirement: Optional note
The toast SHALL offer Add Note. The listener SHALL be able to add or edit a bookmark's note later in the Bookmarks tab. A bookmark without a note MUST be kept.

#### Scenario: Add a note from the toast
- **WHEN** the listener taps Add Note on the toast and saves "great point"
- **THEN** the bookmark's note is "great point"

### Requirement: Bookmarks tab
The system SHALL list bookmarks in a Bookmarks tab, grouped by episode with the most recently bookmarked episode first, and each group in position order. Tapping a bookmark SHALL play its episode from the bookmark's position when the episode is still known. The listener SHALL be able to delete a bookmark.

#### Scenario: Play from a bookmark
- **WHEN** the listener taps a bookmark at 12:34
- **THEN** its episode plays from 12:34

### Requirement: Search bookmarks
The Bookmarks tab SHALL filter bookmarks by text in the note, episode title, or show title, ignoring case.

#### Scenario: Search a note
- **WHEN** the listener searches "GREAT" and a bookmark's note is "great point"
- **THEN** that bookmark is listed

### Requirement: Markdown export
The system SHALL share each episode's bookmarks as one Markdown file through the share sheet. The file MUST hold the episode title, show title, audio address, and each bookmark's position and note.

#### Scenario: Export an episode
- **WHEN** the listener exports an episode with 2 bookmarks
- **THEN** the share sheet offers one Markdown file named after the show and episode, listing both bookmarks in position order
