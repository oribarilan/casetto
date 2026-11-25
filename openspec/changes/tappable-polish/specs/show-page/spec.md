## MODIFIED Requirements

### Requirement: Show header
The show page SHALL open with the show's artwork, title, and author, and two lines of its description without HTML. When the description is longer than two lines, Show more MUST show under it, and tapping anywhere on the description MUST show the rest, with Show less under it to fold it again. A description that fits in two lines MUST show in full, with neither Show more nor Show less. The navigation bar MUST NOT repeat the title.

#### Scenario: Long description
- **WHEN** a show's description runs to several lines
- **THEN** the header shows two lines and Show more, and tapping the description shows the rest with Show less

#### Scenario: Short description
- **WHEN** a show's description fits in two lines
- **THEN** the header shows it with no Show more

#### Scenario: Fold again
- **WHEN** the listener has opened a long description and taps it again
- **THEN** it folds back to two lines with Show more
