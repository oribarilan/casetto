## ADDED Requirements

### Requirement: Starred shows
The listener SHALL be able to star a followed show as a favorite, separate from where its new episodes go. Starring a show whose new episodes go to the Inbox MUST set them to the Queue; other settings stay. The setting MAY change later and the show stays starred. Unstarring MUST remove only the star. The Shows tab SHALL list starred shows under "Starred", then the rest under "More Shows", both A to Z.

#### Scenario: Star an Inbox show
- **WHEN** the listener stars a followed show whose new episodes go to the Inbox
- **THEN** the show is starred and its new episodes go to the end of the Queue

#### Scenario: Star a Play next show
- **WHEN** the listener stars a show set to Play next
- **THEN** the show is starred and stays set to Play next

#### Scenario: Change the setting of a starred show
- **WHEN** the listener sets a starred show's new episodes to the Inbox
- **THEN** its new episodes go to the Inbox and the show stays starred

#### Scenario: Unstar
- **WHEN** the listener unstars a show set to Queue
- **THEN** the show is no longer starred and stays set to Queue

#### Scenario: Shows tab sections
- **WHEN** the listener follows 9 shows and has starred 3
- **THEN** the Shows tab lists the 3 under "Starred" and the other 6 under "More Shows"

#### Scenario: Nothing starred
- **WHEN** no followed show is starred
- **THEN** the Shows tab shows one grid with no headings

### Requirement: Star on episode rows
An episode of a starred show SHALL show a small gray star at the start of its status line in the Queue and the Inbox. A show page MUST leave it out.

#### Scenario: Starred show in the Queue
- **WHEN** a Queue episode belongs to a starred show
- **THEN** its status line starts with a small gray star

#### Scenario: Starred show's own page
- **WHEN** the listener opens a starred show's page
- **THEN** its episode rows show no star
