# discovery Specification

## Purpose
Helps a new listener find and follow shows without knowing any feed address.

## Requirements

### Requirement: Top shows
The system SHALL list Apple's top podcasts for the chart country, in chart order, from Apple's documented chart. The heading SHALL be "Popular now · " followed by the chart country's name, or "Popular now" when the phone has no region. Shows without a feed address MUST be left out. A directory request MUST give up after 10 seconds, and a failed chart request MUST be retried once. If the chart still fails, the system SHALL say so with Cassy and offer Try Again.

#### Scenario: Browse top shows
- **WHEN** the phone's region is the United States and the listener opens the top shows
- **THEN** the list shows each show's title, author, and artwork in chart order under "Popular now · United States"

#### Scenario: Directory unreachable
- **WHEN** the chart fails twice in a row
- **THEN** Cassy says "I couldn't load the top shows." with "Search still works." and a Try Again button

#### Scenario: One failure
- **WHEN** the first chart request fails and the retry succeeds
- **THEN** the top shows appear as if nothing failed

### Requirement: Search
The system SHALL search the directory by name through the iTunes Search API, in the chart country's store, from Find Shows. A search MUST wait until typing pauses, so it stays within the API's rate limit. The Shows tab's search covers only followed shows, as Search your shows says.

#### Scenario: Search by name
- **WHEN** the listener types "planet money" in Find Shows and pauses
- **THEN** matching shows appear, each with a subscribe button

#### Scenario: Empty search
- **WHEN** the listener follows shows, taps the Shows tab's search field, and types nothing
- **THEN** the grid of their shows stays as it is, with no directory shows

### Requirement: Subscribe and star from the directory
Each directory show SHALL offer Follow, which starts the show at the Inbox level, and Star, which follows it at the Auto-queue level. Tapping Star again MUST return the show to the Inbox level. Tapping a followed show's Follow button again MUST unfollow. Tapping the rest of the row MUST open the show's page.

#### Scenario: Star a show
- **WHEN** the listener stars a show they don't follow
- **THEN** the system follows it at the Auto-queue level and its newest episode is in the Queue

#### Scenario: Subscribe without a star
- **WHEN** the listener follows a show from search with Follow
- **THEN** its level is Inbox and its newest episode is in the Inbox

#### Scenario: Open a show from Find Shows
- **WHEN** the listener taps the title of a show they don't follow in Find Shows
- **THEN** the show's page opens with its episodes, and the show stays unfollowed

### Requirement: Onboarding
On first launch the system SHALL show one welcome screen, then a skippable Find Shows screen with a large title, top shows, and search. The welcome screen MUST be the only intro screen; everything else is taught with just-in-time tips. Whenever the listener follows no shows, the Shows tab SHALL show Find Shows without the welcome screen. Only one Cassy SHALL be on screen at a time. After the first star her card SHALL cheer.

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

### Requirement: Chart country
The chart country SHALL start as the phone's region, or the United States when the phone has no region. When the region isn't the United States, the Popular now heading MUST be a menu offering the region and the United States, and the choice MUST be kept on this device. Switching to a country with no saved chart MUST show the loading state until the new chart arrives. There SHALL be no worldwide choice, because Apple has no worldwide chart.

#### Scenario: Switch to the United States
- **WHEN** the phone's region is Israel and the listener picks United States from the heading
- **THEN** the list shows the United States chart under "Popular now · United States", and searches use the United States store

#### Scenario: Region is the United States
- **WHEN** the phone's region is the United States
- **THEN** the heading is plain text with no menu

#### Scenario: Choice is kept
- **WHEN** the listener picked United States and later opens Find Shows again
- **THEN** the list still shows the United States chart

#### Scenario: Switching loads
- **WHEN** no United States chart is saved and the listener picks United States from the heading
- **THEN** the Israel list goes away and the loading Cassy shows "Flipping through the shelves…" until the United States chart appears

### Requirement: Find Shows after onboarding
The Shows tab's + menu SHALL offer Find Shows as its first item. It MUST open the onboarding's Find Shows screen, with the top shows, search, Follow and Star, as a sheet without the welcome screen, closed with Done.

#### Scenario: Open from the + menu
- **WHEN** the listener follows shows and picks Find Shows from the + menu
- **THEN** a sheet titled "Find Shows" shows the top shows and search, and Done closes it

### Requirement: Saved charts
The system SHALL keep the last top shows of the phone's region and of the United States on the device. Find Shows MUST show the saved list for the chart country at once and replace it when a fresh chart arrives. Opening Find Shows MUST fetch both charts. When a fresh chart fails and a saved one exists, the saved list MUST stay, with no error.

#### Scenario: Second visit
- **WHEN** the listener opens Find Shows a second time
- **THEN** the top shows from the last visit appear at once, with no loading Cassy, and are replaced when the fresh chart arrives

#### Scenario: Switch after a visit
- **WHEN** the phone's region is Israel, Find Shows has loaded once, and the listener picks United States
- **THEN** the United States chart appears at once

#### Scenario: Offline with a saved chart
- **WHEN** the listener opens Find Shows offline after an earlier visit
- **THEN** the saved top shows appear, with their art
