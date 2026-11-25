## MODIFIED Requirements

### Requirement: New-episode settings
The show page SHALL show where the show's new episodes go in one row that reads "New episodes go to", with the current choice (Inbox, Queue, Play next, or Skip) and an up-down chevron on the right. Tapping the row MUST open a menu in place with the four choices, each with its short explanation: Inbox "Wait for me to decide", Queue "Add to the end", Play next "Right after what's playing", Skip "Only on this page". When the choice is Inbox, a second row SHALL read "Removed after" with the period on the right, for example "14 days". Its menu MUST list My default, with the default period beside it, then 1, 3, 7, 14, and 30 days, and Never, with a check on the current one. My default MUST follow the global period; any other choice MUST give the show its own period. The show page MUST NOT open a sheet for these settings.

#### Scenario: Change to Play next
- **WHEN** the listener taps the New episodes row on an Inbox show and picks Play next
- **THEN** the row reads "New episodes go to: Play next" and the Removed after row goes away

#### Scenario: Own value
- **WHEN** the listener taps the Removed after row on an Inbox show and picks 3 days
- **THEN** the row reads "Removed after: 3 days", and that show's Inbox episodes are removed after 3 days whatever the default is

#### Scenario: Back to the default
- **WHEN** a show has its own period of 3 days, the default is 14 days, and the listener picks My default
- **THEN** the row reads "Removed after: 14 days" and the show follows the default from then on

### Requirement: Follow and Star on the show page
The show page SHALL show two buttons under the header. Follow MUST be a tangerine capsule that reads Follow, and once followed it MUST turn grey and read Following. Star MUST be a round icon button beside it, showing a star, or a filled tangerine star once starred, and VoiceOver MUST read it as Star or Starred. Follow MUST be the only tangerine capsule on the page. Star MUST work as in the directory: it stars the show, following it if needed, and tapping Starred removes only the star. Tapping Following MUST ask to confirm, then unfollow. The question MUST point at the Following button. The page's menu MUST NOT hold Unfollow.

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

#### Scenario: Following is grey
- **WHEN** the listener opens the page of a show they follow
- **THEN** the Following button is grey, not tangerine

## ADDED Requirements

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
