## MODIFIED Requirements

### Requirement: Bookmark without pausing
The system SHALL let the listener bookmark the current episode and position with one tap in Now Playing. The mini player MUST NOT have a bookmark button. Playback MUST continue. A bookmark MUST keep the show title, episode title, and audio address.

#### Scenario: Bookmark while playing
- **WHEN** the listener taps the bookmark button at 12:34
- **THEN** a bookmark at 12:34 is saved, playback continues, and a toast says "Bookmarked at 12:34"

#### Scenario: Episode leaves the feed
- **WHEN** a bookmarked episode is no longer in its feed, or the listener unsubscribes from its show
- **THEN** the bookmark still shows its show title, episode title, and position

#### Scenario: Mini player
- **WHEN** an episode is loaded and the listener looks at the mini player
- **THEN** it shows the art, the titles, and play or pause, and no bookmark button
