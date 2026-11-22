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
The page of a show the listener doesn't follow, reached from a shared episode in Now Playing or from Find Shows, SHALL show the show header, the Follow and Star buttons, and the show's episodes, fetching its feed without following it when the device doesn't have it. It MUST NOT show the new-episode settings. Following MUST work like following from the directory.

#### Scenario: Subscribe from a shared episode
- **WHEN** the listener plays a shared ATP episode, taps "Accidental Tech Podcast" in Now Playing, and taps Follow
- **THEN** ATP is followed, its page shows the new-episode settings, and the shared episode keeps its place in the Queue

### Requirement: Follow and Star on the show page
The show page SHALL show two buttons under the header: Follow, or Following once followed, and Star, or Starred once starred. Star MUST work as in the directory: it follows the show at the Auto-queue level, and tapping Starred returns it to the Inbox level. Tapping Following MUST ask to confirm, then unfollow. The page's menu MUST NOT hold Unfollow.

#### Scenario: Star from the show page
- **WHEN** the listener follows Planet Money at the Inbox level and taps Star on its page
- **THEN** the button says Starred and the New episodes row says new episodes go to the end of the Queue

#### Scenario: Unfollow from the show page
- **WHEN** the listener taps Following on Planet Money's page and confirms Unfollow
- **THEN** Planet Money is no longer followed and its page shows Follow and Star
