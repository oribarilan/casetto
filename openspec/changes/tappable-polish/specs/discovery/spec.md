## MODIFIED Requirements

### Requirement: Chart country
The chart country SHALL start as the phone's region, or the United States when the phone has no region. When the region isn't the United States, the Popular now heading MUST be a menu offering the region and the United States, with the country name in the accent color, and the choice MUST be kept on this device. Switching to a country with no saved chart MUST show the loading state until the new chart arrives. There SHALL be no worldwide choice, because Apple has no worldwide chart.

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

#### Scenario: Country looks tappable
- **WHEN** the phone's region is Israel and the listener opens Find Shows
- **THEN** "Israel" in the heading is in the accent color, like the chevron after it
