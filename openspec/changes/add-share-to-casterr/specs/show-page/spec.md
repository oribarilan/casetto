## ADDED Requirements

### Requirement: Page of a show you don't follow
The page of a show the listener doesn't follow, reached from a shared episode in Now Playing, SHALL show the show header, a Subscribe button in place of the new-episode settings, and the episodes the feed cache has, with no Unsubscribe action. Subscribing MUST work like subscribing from the directory.

#### Scenario: Subscribe from a shared episode
- **WHEN** the listener plays a shared ATP episode, taps "Accidental Tech Podcast" in Now Playing, and taps Subscribe
- **THEN** ATP is followed, its page shows the new-episode settings, and the shared episode keeps its place in the Queue
