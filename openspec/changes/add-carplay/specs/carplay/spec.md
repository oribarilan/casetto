## ADDED Requirements

### Requirement: Queue in the car
When the phone is connected to CarPlay, the system SHALL show the Queue in play order as the only list. Each item SHALL show the episode title, the show title, and the show art. Tapping an item SHALL play it, and Now Playing SHALL open. The car MUST NOT offer triage, the Inbox, Shows, or Bookmarks.

#### Scenario: Play from the Queue in the car
- **WHEN** the listener taps the second Queue item on the car screen
- **THEN** that episode plays, moves to the top of the Queue, and the car shows Now Playing

#### Scenario: Empty Queue in the car
- **WHEN** the Queue is empty
- **THEN** the car screen says "Your Queue is empty" and "Starred shows' new episodes show up here.", and never tells the driver to use the phone

### Requirement: Now Playing in the car
The car's Now Playing screen SHALL offer play, pause, skip back 15 seconds, skip forward 30 seconds, a bookmark button, and a speed button.

#### Scenario: Bookmark in the car
- **WHEN** the listener taps the bookmark button at 12:34 in the car
- **THEN** a bookmark at 12:34 is saved without a note and playback continues

#### Scenario: Speed in the car
- **WHEN** the show plays at 1.3x and the listener taps the speed button in the car
- **THEN** playback moves to 1.4x, and 1.4x becomes the show's own speed, as if set from the phone's Now Playing

#### Scenario: Speed wraps around
- **WHEN** the show plays at 2.0x and the listener taps the speed button
- **THEN** playback moves to 1.0x

#### Scenario: Bookmark confirms in place
- **WHEN** the listener taps the bookmark button in the car
- **THEN** the bookmark icon shows filled for 2 seconds, then returns to outline
