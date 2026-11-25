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
The show page SHALL show where the show's new episodes go in one row that reads "New episodes go to", with the current choice (Inbox, Queue, Play next, or Skip) and an up-down chevron on the right. Tapping the row MUST open a menu in place with the four choices, each with its short explanation: Inbox "Wait for me to decide", Queue "Add to the end", Play next "Right after what's playing", Skip "Only on this page". The show page MUST NOT open a sheet for these settings.

#### Scenario: Change to Play next
- **WHEN** the listener taps the New episodes row on an Inbox show and picks Play next
- **THEN** the row reads "New episodes go to: Play next" and the Removed after row goes away

### Requirement: Inbox period on the show page
When a show's new episodes go to the Inbox, its page SHALL show a second row that reads "Removed after" with the period on the right, for example "14 days". Its menu MUST list My default, with the default period beside it, then 1, 3, 7, 14, and 30 days, and Never, with a check on the current one. My default MUST follow the global period; any other choice MUST give the show its own period.

#### Scenario: Own value
- **WHEN** the listener taps the Removed after row on an Inbox show and picks 3 days
- **THEN** the row reads "Removed after: 3 days", and that show's Inbox episodes are removed after 3 days whatever the default is

#### Scenario: Back to the default
- **WHEN** a show has its own period of 3 days, the default is 14 days, and the listener picks My default
- **THEN** the row reads "Removed after: 14 days" and the show follows the default from then on

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
The show page SHALL show Follow, or Following once followed, and Star, or Starred once starred, under the header. Star MUST work as in the directory: it stars the show, following it if needed, and tapping Starred removes only the star. Tapping Following MUST ask to confirm, then unfollow. The question MUST point at the Following button. The page's menu MUST NOT hold Unfollow.

#### Scenario: Star from the show page
- **WHEN** the listener follows Planet Money at the Inbox level and taps Star on its page
- **THEN** the star fills and the New episodes row reads Queue

#### Scenario: Unstar from the show page
- **WHEN** the listener taps the filled star on a show set to Queue
- **THEN** the star empties and the New episodes row still reads Queue

#### Scenario: Unfollow from the show page
- **WHEN** the listener taps Following on Planet Money's page and confirms Unfollow
- **THEN** Planet Money is no longer followed and its page shows the tangerine Follow and an empty star

#### Scenario: Unfollow question points at Following
- **WHEN** the listener taps Following on Planet Money's page
- **THEN** the question "Episodes you queued stay in your Queue." opens pointing at the Following button

### Requirement: Look of Follow and Star on the show page
Follow SHALL be a tangerine capsule, and once followed it MUST turn grey. It MUST be the only tangerine capsule on the page. Star MUST be a round icon button beside it, showing a star, or a filled tangerine star once starred, and VoiceOver MUST read it as Star or Starred.

#### Scenario: Following is grey
- **WHEN** the listener opens the page of a show they follow
- **THEN** the Following button is grey, not tangerine

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

### Requirement: New episodes row appears at once
When the listener taps Follow or Star on the page of a show they don't follow, the New episodes row SHALL appear at once with the choice the follow will have (Inbox for Follow, Queue for Star), without waiting for the save or the feed. A choice made from the row while the follow is still saving MUST be kept. If the follow fails, the row MUST go away.

#### Scenario: Follow shows the row at once
- **WHEN** the listener taps Follow on the page of a show they don't follow
- **THEN** the New episodes row appears at once reading Inbox, with Removed after under it, before the feed has loaded

#### Scenario: Star shows Queue at once
- **WHEN** the listener taps Star on the page of a show they don't follow
- **THEN** the New episodes row appears at once reading Queue, with no Removed after row

#### Scenario: Choice during the save
- **WHEN** the listener taps Follow and picks Skip from the row's menu before the follow has saved
- **THEN** the row keeps reading Skip, and the show is followed at Skip once the save lands

### Requirement: New episodes row moves smoothly
The New episodes row SHALL grow into place when it appears, with the episode list sliding down, and shrink away when it goes, with the list sliding up. A changed choice MUST cross-fade, and the Removed after row MUST grow in or shrink away with it. With Reduce Motion on, the rows MUST appear, go, and change without movement.

#### Scenario: Follow grows the row
- **WHEN** the listener taps Follow
- **THEN** the New episodes row grows in and the episode list slides down

#### Scenario: Unfollow
- **WHEN** the listener confirms Unfollow
- **THEN** the New episodes row shrinks away and the episode list slides up

#### Scenario: Reduce Motion
- **WHEN** Reduce Motion is on and the listener taps Follow
- **THEN** the New episodes row appears without growing
