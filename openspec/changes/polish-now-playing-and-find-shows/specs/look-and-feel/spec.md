## MODIFIED Requirements

### Requirement: Now Playing tint
Now Playing SHALL use a background color taken from the show's artwork, darkened enough for white text to stay readable. Now Playing SHALL show the standard iOS grab handle at its top, so the listener can see it swipes down to close.

#### Scenario: Tinted background
- **WHEN** an episode with mostly green artwork is playing
- **THEN** Now Playing has a dark green background with white text

#### Scenario: Grab handle
- **WHEN** the listener opens Now Playing
- **THEN** a grab handle shows at the top of the sheet
