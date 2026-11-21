# show-page Specification

## Purpose
What a show page shows: the show, what happens to its new episodes, and its episodes.

## Requirements

### Requirement: Show header
The show page SHALL open with the show's artwork, title, and author, and two lines of its description without HTML, with More to expand it. The navigation bar MUST NOT repeat the title.

#### Scenario: Long description
- **WHEN** a show's description runs to several lines
- **THEN** the header shows two lines and More, and More shows the rest

### Requirement: New-episode settings
The show page SHALL summarize what happens to the show's new episodes in one row, such as "Go to your Inbox, removed after 14 days (your default)". Tapping it SHALL open a half sheet with four choices (Inbox, Queue, Play next, Skip), each with a one-line description. For Inbox, the sheet SHALL show a "Use my default" toggle; turning it off MUST show the presets 1d, 3d, 7d, 14d, 30d, and Never, starting at the current default.

#### Scenario: Change to Play next
- **WHEN** the listener opens the sheet and taps Play next
- **THEN** the Inbox period controls disappear and the summary reads "Play next, right after what's playing"

#### Scenario: Own value
- **WHEN** the listener turns off "Use my default" and picks 3d
- **THEN** the summary reads "Go to your Inbox, removed after 3 days"

### Requirement: Played episodes folded
Played episodes SHALL be folded into one "Played (N)" row above the episode list, collapsed by default, so the list shows what's left to hear and the played ones stay one tap away however long the back catalog is.

#### Scenario: Mark played
- **WHEN** the listener marks an episode played
- **THEN** it leaves the episode list and the Played row counts it

### Requirement: Page of a show you don't follow
The page of a show the listener doesn't follow, reached from a shared episode in Now Playing, SHALL show the show header, a Subscribe button in place of the new-episode settings, and the episodes the feed cache has, with no Unsubscribe action. Subscribing MUST work like subscribing from the directory.

#### Scenario: Subscribe from a shared episode
- **WHEN** the listener plays a shared ATP episode, taps "Accidental Tech Podcast" in Now Playing, and taps Subscribe
- **THEN** ATP is followed, its page shows the new-episode settings, and the shared episode keeps its place in the Queue
