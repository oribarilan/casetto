## ADDED Requirements

### Requirement: Headphone and car buttons
The system SHALL answer the next and previous commands, which AirPods send for a double and a triple press and other headphones and cars send from their next and previous buttons, with the action chosen in Settings: skip forward 30, skip back 15, or bookmark. A bookmark MUST save like the Now Playing Bookmark, keep playing, and play a short chime, also with silent mode on. The lock screen MUST keep its 15 and 30 buttons.

#### Scenario: Double press with the defaults
- **WHEN** an episode plays at 12:34 and the listener double presses an AirPod
- **THEN** a bookmark at 12:34 is saved, a chime plays over the episode, and playback continues

#### Scenario: Triple press with the defaults
- **WHEN** the listener triple presses an AirPod
- **THEN** playback moves 15 seconds earlier

#### Scenario: Silent mode
- **WHEN** silent mode is on and the listener bookmarks with a double press
- **THEN** the chime still plays

#### Scenario: Car buttons
- **WHEN** the listener presses next on the car's steering wheel with double press set to Skip forward 30
- **THEN** playback moves 30 seconds later

#### Scenario: Lock screen
- **WHEN** the listener looks at the lock screen while an episode plays
- **THEN** it shows the skip back 15 and skip forward 30 buttons, not next and previous track

#### Scenario: Nothing loaded
- **WHEN** no episode is loaded and a next or previous command arrives
- **THEN** nothing is saved and no chime plays
