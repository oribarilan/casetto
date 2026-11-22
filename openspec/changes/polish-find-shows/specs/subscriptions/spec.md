## MODIFIED Requirements

### Requirement: Search your shows
Searching on the Shows tab SHALL show only the shows the listener follows that match, in the grid, and no shows from the directory. A followed show MUST match when every word of the search appears in its title or author, ignoring case and accents. With no match, the tab MUST say so. While the listener follows no shows, the Shows tab is Find Shows and its search covers the directory.

#### Scenario: Split results
- **WHEN** the listener follows Planet Money and searches "planet"
- **THEN** the grid shows only Planet Money, and no directory shows appear

#### Scenario: Partial words
- **WHEN** the listener searches "pock econ"
- **THEN** a followed show named Pocket Economics matches

#### Scenario: No match
- **WHEN** the listener follows Planet Money and searches "zzz"
- **THEN** the tab says no shows match "zzz"
