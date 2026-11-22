## MODIFIED Requirements

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
