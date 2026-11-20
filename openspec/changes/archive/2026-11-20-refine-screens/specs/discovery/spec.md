# Spec Delta

## MODIFIED Requirements

### Requirement: Top shows
The system SHALL list Apple's top podcasts for the listener's country, in chart order, from Apple's documented chart. Shows without a feed address MUST be left out. A directory request MUST give up after 10 seconds, and a failed chart request MUST be retried once. If the chart still fails, the system SHALL say so with Cassy and offer Try Again.

#### Scenario: Browse top shows
- **WHEN** the listener opens the top shows
- **THEN** the list shows each show's title, author, and artwork in chart order

#### Scenario: Directory unreachable
- **WHEN** the chart fails twice in a row
- **THEN** Cassy says "I couldn't load the top shows." with "Search still works." and a Try Again button

#### Scenario: One failure
- **WHEN** the first chart request fails and the retry succeeds
- **THEN** the top shows appear as if nothing failed

### Requirement: Onboarding
On first launch the system SHALL show a skippable Find Shows screen with a large title, top shows, and search. Whenever the listener follows no shows, the Shows tab SHALL show the same view. Only one Cassy SHALL be on screen at a time: while the list loads she is big and loading, and once it has loaded she is in a card above the list that explains it and how to follow. After the first star the card SHALL cheer.

#### Scenario: First launch
- **WHEN** the app launches for the first time
- **THEN** the onboarding screen shows, and Done or Skip closes it

#### Scenario: Loading
- **WHEN** the top shows are loading
- **THEN** one big loading Cassy says "Flipping through the shelves…", and no list or card is shown

#### Scenario: Loaded
- **WHEN** the top shows have loaded
- **THEN** a card says "These are popular right now." with "Tap + to follow any of them, or search for a show you love."

#### Scenario: First star
- **WHEN** the listener stars a show in onboarding
- **THEN** the card cheers "Nice pick!" with "I'll queue its new episodes. Keep going, or tap Done."

#### Scenario: Unsubscribed from everything
- **WHEN** the listener follows no shows and opens the Shows tab
- **THEN** it shows the top shows and search

## ADDED Requirements

### Requirement: Just-in-time tips
The system SHALL teach a control with a one-time tip at the moment the listener first needs it, instead of up-front tutorials. A tip SHALL be a sticker bubble from Cassy that points at the control, with a subtle grey ✕. It MUST close on its ✕ or any other tap, and MUST show at most once per install.

#### Scenario: First follow teaches the star
- **WHEN** the listener follows a show with + for the first time and hasn't starred one
- **THEN** a tip on that show's star says "Never miss this one? Star it and I'll queue its new episodes."

#### Scenario: Starring first
- **WHEN** the listener stars a show before ever following one with +
- **THEN** the star tip never shows

#### Scenario: Close
- **WHEN** the listener taps the tip's ✕ or anywhere else
- **THEN** the tip closes and doesn't show again
