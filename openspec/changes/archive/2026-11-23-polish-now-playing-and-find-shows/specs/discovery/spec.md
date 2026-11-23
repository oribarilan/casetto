## MODIFIED Requirements

### Requirement: Onboarding
On first launch the system SHALL show one welcome screen, then a skippable Find Shows screen with a large title, top shows, and search. The welcome screen MUST be the only intro screen; everything else is taught with just-in-time tips. Whenever the listener follows no shows, the Shows tab SHALL show Find Shows without the welcome screen. Only one Cassy SHALL be on screen at a time. Her card SHALL cheer after the listener stars a show during the current visit to Find Shows, and only then.

#### Scenario: First launch
- **WHEN** the app launches for the first time
- **THEN** the welcome screen shows Cassy, "Hi, I'm Cassy!", one sentence on what Casterr does, three numbered steps ("Follow shows", "Queue the episodes you want", "Press play", each with one line: new episodes land in the Inbox, the rest leave on their own after 14 days, the Queue plays top to bottom), and one button, "Let's add some shows"
- **AND** that button opens Find Shows, and Done or Skip there closes onboarding

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

#### Scenario: Starred before this visit
- **WHEN** the listener starred a show earlier, then opens Find Shows from the + menu
- **THEN** the card says "Let's add some shows!", not "Nice pick!"

#### Scenario: Star taken back
- **WHEN** the listener stars a show in Find Shows, then unstars it during the same visit
- **THEN** the card goes back to "Let's add some shows!"
