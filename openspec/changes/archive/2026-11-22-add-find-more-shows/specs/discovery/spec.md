## MODIFIED Requirements

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
The system SHALL search podcasts by name through the iTunes Search API, in the chart country's store, from the Shows tab and Find Shows. A search MUST wait until typing pauses, so it stays within the API's rate limit. While the Shows tab's search field is active and empty, it SHALL show the top shows.

#### Scenario: Search by name
- **WHEN** the listener types "planet money" and pauses
- **THEN** matching shows appear, each with a subscribe button

#### Scenario: Empty search
- **WHEN** the listener follows shows, taps the Shows tab's search field, and types nothing
- **THEN** the top shows appear under "Popular now", each with Subscribe and Star

## ADDED Requirements

### Requirement: Chart country
The chart country SHALL start as the phone's region, or the United States when the phone has no region. When the region isn't the United States, the Popular now heading MUST be a menu offering the region and the United States, and the choice MUST be kept on this device. There SHALL be no worldwide choice, because Apple has no worldwide chart.

#### Scenario: Switch to the United States
- **WHEN** the phone's region is Israel and the listener picks United States from the heading
- **THEN** the list shows the United States chart under "Popular now · United States", and searches use the United States store

#### Scenario: Region is the United States
- **WHEN** the phone's region is the United States
- **THEN** the heading is plain text with no menu

#### Scenario: Choice is kept
- **WHEN** the listener picked United States and later opens Find Shows again
- **THEN** the list still shows the United States chart

### Requirement: Find Shows after onboarding
The Shows tab's + menu SHALL offer Find Shows as its first item. It MUST open the onboarding's Find Shows screen, with the top shows, search, Subscribe and Star, as a sheet without the welcome screen, closed with Done.

#### Scenario: Open from the + menu
- **WHEN** the listener follows shows and picks Find Shows from the + menu
- **THEN** a sheet titled "Find Shows" shows the top shows and search, and Done closes it
