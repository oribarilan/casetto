## MODIFIED Requirements

### Requirement: Global defaults
The system SHALL have a Settings screen, opened from a gear on the Queue, with only the global defaults: how long unplayed episodes wait in the Inbox (1d, 3d, 7d, 14d, 30d, Never), how many Queue episodes stay downloaded (Off, 1, 3, 5, 10), the default speed, and whether voice boost is on. Each SHALL say how it relates to per-show settings. A link from elsewhere MUST be able to open Settings at a section, briefly highlighted.

#### Scenario: Open from the Inbox
- **WHEN** the listener taps the expiry line in the Inbox
- **THEN** Settings opens with the Inbox section highlighted

#### Scenario: Turn downloads off
- **WHEN** the listener sets Keep downloaded to Off
- **THEN** downloaded files are deleted and no download starts

#### Scenario: Turn voice boost on
- **WHEN** the listener turns on Voice boost in the Playback section, under Default speed
- **THEN** the playing episode gets the boost right away if its show has no choice of its own, and the footer says a show can have its own from Now Playing
