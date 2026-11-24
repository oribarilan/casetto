## ADDED Requirements

### Requirement: Headphone and car buttons setting
Settings SHALL have a "Headphone and car buttons" section right after Playback, with two pickers, Double press and Triple press. Each MUST offer Skip forward 30, Skip back 15, and Bookmark. The defaults MUST be Bookmark for double press and Skip back 15 for triple press. The footer MUST say what each press does now, joined into one sentence when both match, and that other headphones and cars do the same with their next and previous buttons.

#### Scenario: Defaults
- **WHEN** the listener opens Settings for the first time
- **THEN** Double press shows Bookmark, Triple press shows Skip back 15, and the footer reads "Double press bookmarks, with a chime. Triple press skips back 15. Other headphones and cars do the same with their next and previous buttons."

#### Scenario: Change a press
- **WHEN** the listener sets Triple press to Skip forward 30
- **THEN** the footer says "Triple press skips forward 30" and the next triple press skips forward

#### Scenario: Both the same
- **WHEN** the listener sets both presses to Skip forward 30
- **THEN** the footer starts with "Double and triple press skip forward 30."

#### Scenario: Another device
- **WHEN** the listener changes Double press on one iPhone signed in to the same iCloud account as another
- **THEN** the other iPhone uses the new choice after it syncs
