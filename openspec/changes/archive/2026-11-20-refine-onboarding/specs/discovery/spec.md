## MODIFIED Requirements

### Requirement: Top shows
The system SHALL list Apple's top podcasts for the listener's country, in chart order, from Apple's documented chart. The heading SHALL be "Popular now · " followed by the name of the phone's region, or "Popular now" when the phone has no region. Shows without a feed address MUST be left out. A directory request MUST give up after 10 seconds, and a failed chart request MUST be retried once. If the chart still fails, the system SHALL say so with Cassy and offer Try Again.

#### Scenario: Browse top shows
- **WHEN** the phone's region is the United States and the listener opens the top shows
- **THEN** the list shows each show's title, author, and artwork in chart order under "Popular now · United States"

#### Scenario: Directory unreachable
- **WHEN** the chart fails twice in a row
- **THEN** Cassy says "I couldn't load the top shows." with "Search still works." and a Try Again button

#### Scenario: One failure
- **WHEN** the first chart request fails and the retry succeeds
- **THEN** the top shows appear as if nothing failed

### Requirement: Onboarding
On first launch the system SHALL show one welcome screen, then a skippable Find Shows screen with a large title, top shows, and search. The welcome screen SHALL have Cassy, the line "Hi, I'm Cassy!", one sentence on what Casterr does, three numbered steps ("Follow shows", "Queue the episodes you want", "Press play", each with one line that says new episodes land in the Inbox, the rest leave on their own after 14 days, and the Queue plays top to bottom), and one button, "Let's add some shows", that opens Find Shows. The welcome screen MUST be the only intro screen; everything else is taught with just-in-time tips. Whenever the listener follows no shows, the Shows tab SHALL show the Find Shows view without the welcome screen. Only one Cassy SHALL be on screen at a time: while the list loads she is big and loading, and once it has loaded she is in a card above the list that invites the listener to add shows. After the first star the card SHALL cheer.

#### Scenario: First launch
- **WHEN** the app launches for the first time
- **THEN** the welcome screen shows; "Let's add some shows" opens Find Shows, and Done or Skip there closes onboarding

#### Scenario: Loading
- **WHEN** the top shows are loading
- **THEN** one big loading Cassy says "Flipping through the shelves…", and no list or card is shown

#### Scenario: Loaded
- **WHEN** the top shows have loaded
- **THEN** a card says "Let's add some shows!" with "Tap + to follow one, or search for a show you love."

#### Scenario: First star
- **WHEN** the listener stars a show in onboarding
- **THEN** the card cheers "Nice pick!" with "I'll queue its new episodes. Keep going, or tap Done."

#### Scenario: Unsubscribed from everything
- **WHEN** the listener follows no shows and opens the Shows tab
- **THEN** it shows the top shows and search, without the welcome screen
