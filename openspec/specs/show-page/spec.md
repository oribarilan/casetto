# show-page Specification

## Purpose
What a show page shows: the show, what happens to its new episodes, and its episodes.

## Requirements

### Requirement: Show header
The show page SHALL open with the show's artwork, title, and author, and two lines of its description without HTML. When the description is longer than two lines, Show more MUST show under it, and tapping anywhere on the description MUST show the rest, with Show less under it to fold it again. A description that fits in two lines MUST show in full, with neither Show more nor Show less. The navigation bar MUST NOT repeat the title.

#### Scenario: Long description
- **WHEN** a show's description runs to several lines
- **THEN** the header shows two lines and Show more, and tapping the description shows the rest with Show less

#### Scenario: Short description
- **WHEN** a show's description fits in two lines
- **THEN** the header shows it with no Show more

#### Scenario: Fold again
- **WHEN** the listener has opened a long description and taps it again
- **THEN** it folds back to two lines with Show more

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
The show page SHALL show two buttons under the header: Follow, or Following once followed, and Star, or Starred once starred. Star MUST work as in the directory: it stars the show, following it if needed, and tapping Starred removes only the star. Tapping Following MUST ask to confirm, then unfollow. The question MUST point at the Following button. The page's menu MUST NOT hold Unfollow.

#### Scenario: Star from the show page
- **WHEN** the listener follows Planet Money at the Inbox level and taps Star on its page
- **THEN** the button says Starred and the New episodes row says new episodes go to the end of the Queue

#### Scenario: Unstar from the show page
- **WHEN** the listener taps Starred on a show set to Queue
- **THEN** the button says Star and the New episodes row still says the end of the Queue

#### Scenario: Unfollow from the show page
- **WHEN** the listener taps Following on Planet Money's page and confirms Unfollow
- **THEN** Planet Money is no longer followed and its page shows Follow and Star

#### Scenario: Unfollow question points at Following
- **WHEN** the listener taps Following on Planet Money's page
- **THEN** the question "Episodes you queued stay in your Queue." opens pointing at the Following button

### Requirement: Show page while loading
While a show's feed loads, the show page SHALL keep its final layout, with shimmering placeholders for the art, title, author, two lines of description, and four episode rows, in place of a spinner. A show opened from Find Shows MUST show the name, host and art from the directory at once and keep that art after the feed arrives. With Reduce Motion on, the placeholders MUST stay still.

#### Scenario: Open from Find Shows
- **WHEN** the listener taps a show in Find Shows that isn't on the phone
- **THEN** its page shows the directory's name, host and art right away, shimmering bars for the description and four shimmering episode rows, and then the description and episodes fill in place

#### Scenario: No directory details
- **WHEN** a show page opens with nothing known about the show yet
- **THEN** the art, title and author are shimmering placeholders too, until the feed arrives

#### Scenario: Reduce Motion
- **WHEN** Reduce Motion is on and a show page is loading
- **THEN** the placeholders are plain gray shapes that don't move

### Requirement: Long episode lists
The show page SHALL show the newest 30 episodes of its Episodes list, then a "Show older episodes" row when more remain. Each tap MUST add the next 30 without moving what's already shown. The open Played list MUST work the same way, and its count MUST still count every played episode. Each visit to the page MUST start at 30.

#### Scenario: A long back catalog
- **WHEN** the listener opens a show with 2,787 episodes
- **THEN** the page shows the newest 30 and a "Show older episodes" row at the end

#### Scenario: Show older episodes
- **WHEN** the listener taps "Show older episodes"
- **THEN** the next 30 episodes appear below the ones already shown, and the row moves to the end again

#### Scenario: A short show
- **WHEN** a show has 12 episodes
- **THEN** all 12 show and there is no "Show older episodes" row

#### Scenario: Played list
- **WHEN** a show has 80 played episodes and the listener opens Played
- **THEN** Played (80) shows the newest 30 played episodes and a "Show older episodes" row
