## MODIFIED Requirements

### Requirement: Up-next bar
While nothing is loaded and the first Queue episode was never started, the bottom bar SHALL offer it with a play button and say "Up next · from your Queue". Tapping the bar SHALL open the Queue. When nothing is loaded and the first Queue episode has progress, the player MUST load it, paused, at its saved position, so the bottom bar is the mini player; loading it MUST NOT count as playing it.

#### Scenario: New episode
- **WHEN** nothing is loaded and the first Queue episode has never been played
- **THEN** the bar says "Up next · from your Queue" and its play button starts it

#### Scenario: Started episode
- **WHEN** the app opens with nothing loaded and the first Queue episode has 25 minutes left
- **THEN** that episode is loaded paused, the bottom bar is the mini player, tapping it opens Now Playing, and play resumes it

#### Scenario: Empty Queue
- **WHEN** nothing is loaded and the Queue is empty
- **THEN** no bar shows
