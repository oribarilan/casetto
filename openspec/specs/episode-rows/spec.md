# episode-rows Specification

## Purpose
Defines how the episode rows in the Queue, the Inbox and show pages behave: what a tap does, which actions each screen offers, and how a row shows the episode's status.

## Requirements

### Requirement: Action line
A tap on an episode row in the Queue, the Inbox or a show page SHALL open a line of round labeled buttons under the row, with Play first, and MUST NOT start playback. Only one line MAY be open at a time: tapping the same row closes it, tapping another row moves it there, and using any action but Share closes it. The swipes and drag to reorder MUST keep working. Rows MUST NOT show an Undo button.

#### Scenario: Tap opens the line
- **WHEN** the listener taps the third Queue row
- **THEN** a line with Play, Play Next, Played, Share, Show and Remove opens under it, and nothing starts playing

#### Scenario: Tap another row
- **WHEN** the line is open under the second row and the listener taps the third row
- **THEN** the line closes under the second row and opens under the third

#### Scenario: Tap the same row
- **WHEN** the line is open under a row and the listener taps that row again
- **THEN** the line closes

#### Scenario: Play from the line
- **WHEN** the listener taps Play in the line
- **THEN** the episode plays, moves to the top of the Queue, and the line closes

#### Scenario: Pause from the line
- **WHEN** the listener opens the line of the episode that is playing
- **THEN** its first button is Pause, and tapping it pauses playback

#### Scenario: Swipes stay
- **WHEN** the listener swipes a Queue row left
- **THEN** Remove shows as before, with no line opening

### Requirement: Actions on each screen
The line SHALL show only the actions that apply. Queue: Play, Play Next (not on the first two rows), Played, Share, Show, Remove. Inbox: Play, Play Next, Add to Queue, Share, Show, Remove. Show page: Play, Play Next (unless first or second in the Queue), Add to Queue (unless queued), Played or Unplayed, Share, Remove (if in the Inbox or Queue), Delete (shared files only). Shared files MUST NOT offer Share.

#### Scenario: Play Next from the Queue
- **WHEN** the listener taps Play Next on the fourth Queue row while the first one plays
- **THEN** that episode becomes second in the Queue and the others keep their order

#### Scenario: First Queue row
- **WHEN** the listener opens the line of the first or second Queue row
- **THEN** it has no Play Next, because Play Next would leave it where it is

#### Scenario: Played from the Queue
- **WHEN** the listener taps Played in a Queue row's line
- **THEN** the episode counts as played and leaves the Queue

#### Scenario: Show from the Inbox
- **WHEN** the listener taps Show in an Inbox row's line
- **THEN** that episode's show page opens

#### Scenario: Remove from a show page
- **WHEN** the listener taps Remove on a show page row whose episode is in the Inbox
- **THEN** it leaves the Inbox and its row reads "Removed"

#### Scenario: Removed from the Queue
- **WHEN** the listener removes an episode from the Queue, from its line or by swiping
- **THEN** its show page row reads "Removed"

#### Scenario: Played episode on its show page
- **WHEN** the listener opens the line of a played episode on its show page
- **THEN** it offers Unplayed instead of Played, and Add to Queue

#### Scenario: Shared file
- **WHEN** the listener opens the line of a file on the Shared with Casterr page
- **THEN** it offers Delete and no Share

### Requirement: Episode status line
Every episode row SHALL show its status as words in one line above the title: Queued, In Inbox, Played, Removed, the reason for an automatic move, and Downloaded, joined by " · ". The words MUST be gray, except "Up next", "Playing" and "Paused" on the first Queue row, which are orange. A word that every row on the screen shares MUST be left out. A played episode's title MUST be gray.

#### Scenario: Queued and downloaded on a show page
- **WHEN** a show page lists an episode that is in the Queue and downloaded
- **THEN** its row reads "Queued · Downloaded" in gray

#### Scenario: First Queue row
- **WHEN** the first Queue episode is downloaded and nothing is loaded
- **THEN** its row reads "Up next" in orange, then "Downloaded" in gray

#### Scenario: Nothing shared is repeated
- **WHEN** the listener opens the Queue or the Inbox
- **THEN** no Queue row says "Queued" and no Inbox row says "In Inbox"

#### Scenario: Played episode
- **WHEN** the listener opens the Played group on a show page
- **THEN** each row reads "Played" in gray and its title is gray

### Requirement: Minutes left on a started episode
A row of an episode that has progress and isn't played SHALL show the minutes left, rounded up, such as "18 min left", in place of its length.

#### Scenario: Started episode
- **WHEN** a 31-minute episode was played for 13 minutes and the listener opens any screen that lists it
- **THEN** its row shows "18 min left" after the date, and no length

#### Scenario: Not started
- **WHEN** an episode has no progress
- **THEN** its row shows its length, such as "31:12"
