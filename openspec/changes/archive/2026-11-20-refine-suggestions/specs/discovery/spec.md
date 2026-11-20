## MODIFIED Requirements

### Requirement: Top shows
The system SHALL list Apple's top podcasts for the listener's country, in chart order, from Apple's documented chart, under the heading "Popular now". Shows without a feed address MUST be left out. A directory request MUST give up after 10 seconds, and a failed chart request MUST be retried once. If the chart still fails, the system SHALL say so with Cassy and offer Try Again.

#### Scenario: Browse top shows
- **WHEN** the listener opens the top shows
- **THEN** the list shows each show's title, author, and artwork in chart order under "Popular now"

#### Scenario: Directory unreachable
- **WHEN** the chart fails twice in a row
- **THEN** Cassy says "I couldn't load the top shows." with "Search still works." and a Try Again button

#### Scenario: One failure
- **WHEN** the first chart request fails and the retry succeeds
- **THEN** the top shows appear as if nothing failed
