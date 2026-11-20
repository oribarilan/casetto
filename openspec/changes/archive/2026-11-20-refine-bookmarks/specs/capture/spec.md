## MODIFIED Requirements

### Requirement: Optional note
The toast SHALL offer Add Note. The listener SHALL be able to add or edit a bookmark's note later in the Bookmarks tab by tapping the note in its row. A bookmark without a note MUST be kept, and its row SHALL say "Add a note".

#### Scenario: Add a note from the toast
- **WHEN** the listener taps Add Note on the toast and saves "great point"
- **THEN** the bookmark's note is "great point"

#### Scenario: Edit a note in place
- **WHEN** the listener taps "Add a note" on a bookmark in the Bookmarks tab, types "check this", and taps Done
- **THEN** the bookmark's note is "check this", with no alert or swipe

### Requirement: Bookmarks tab
The system SHALL list bookmarks in a Bookmarks tab, grouped by episode with the most recently bookmarked episode first, and each group in position order. Each episode SHALL be one card headed by the show art, the episode title, and the show name. Each bookmark's time SHALL be a play button that plays its episode from the bookmark's position when the episode is still known. The listener SHALL be able to delete a bookmark.

#### Scenario: Play from a bookmark
- **WHEN** the listener taps a bookmark at 12:34
- **THEN** its episode plays from 12:34

#### Scenario: Episode left the feed
- **WHEN** a bookmarked episode is no longer known
- **THEN** its time is grey without a play arrow, and a line under its card says it can't play

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
