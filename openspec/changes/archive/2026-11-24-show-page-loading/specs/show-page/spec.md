## ADDED Requirements

### Requirement: Show page while loading
While a show's feed loads, the show page SHALL keep its final layout, with shimmering placeholders for the art, title, author, two lines of description, and four episode rows, in place of a spinner. A show opened from Find Shows MUST show the name, host and art from the directory at once and keep that art after the feed arrives. With Reduce Motion on, the placeholders MUST stay still.

#### Scenario: Open from Find Shows
- **WHEN** the listener taps a show in Find Shows that isn't on the phone
- **THEN** its page shows the directory's name, host and art right away, shimmering bars for the description and four shimmering episode rows, and then the description and episodes fill in place

#### Scenario: No directory details
- **WHEN** a show page opens with nothing known about the show yet
- **THEN** the art, title and author are shimmering placeholders too, until the feed arrives

#### Scenario: Reduce Motion
- **WHEN** Reduce Motion is on and a show page is loading
- **THEN** the placeholders are plain gray shapes that don't move
