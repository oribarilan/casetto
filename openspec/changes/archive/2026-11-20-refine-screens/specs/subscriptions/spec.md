# Spec Delta

## ADDED Requirements

### Requirement: Search your shows
Searching on the Shows tab SHALL list the shows the listener follows that match, first, then more shows from the directory without the ones already followed. A followed show MUST match when every word of the search appears in its title or author, ignoring case and accents.

#### Scenario: Split results
- **WHEN** the listener follows Planet Money and searches "planet"
- **THEN** "Your shows" lists Planet Money, and "More shows" lists other matching shows from the directory but not Planet Money

#### Scenario: Partial words
- **WHEN** the listener searches "pock econ"
- **THEN** a followed show named Pocket Economics matches
