## MODIFIED Requirements

### Requirement: Search
The system SHALL search the directory by name through the iTunes Search API, in the chart country's store, from Find Shows. A search MUST wait until typing pauses, so it stays within the API's rate limit. The Shows tab's search covers only followed shows, as Search your shows says.

#### Scenario: Search by name
- **WHEN** the listener types "planet money" in Find Shows and pauses
- **THEN** matching shows appear, each with a subscribe button

#### Scenario: Empty search
- **WHEN** the listener follows shows, taps the Shows tab's search field, and types nothing
- **THEN** the grid of their shows stays as it is, with no directory shows

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

## ADDED Requirements

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
