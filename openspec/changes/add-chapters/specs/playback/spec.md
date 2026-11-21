## ADDED Requirements

### Requirement: Chapter sources
The system SHALL take an episode's chapters from its audio file, for downloaded and streamed episodes. When the file has none, it SHALL take them from a timestamp list in the episode's show notes: lines that start with a time, with at least two times in increasing order. Times in running prose MUST NOT become chapters. When neither source has chapters, the episode has none.

#### Scenario: Chapters in the file
- **WHEN** an episode's audio file has 12 embedded chapters
- **THEN** the episode has those 12 chapters with their titles and start times

#### Scenario: Chapters in the show notes
- **WHEN** an episode's file has no chapters and its notes list "0:00 פתיחה", "2:30 וויקלי סינק", and "5:51 ג׳נסן שובב" on separate lines
- **THEN** the episode has 3 chapters starting at 0:00, 2:30, and 5:51

#### Scenario: The file wins
- **WHEN** an episode has chapters in both its file and its notes
- **THEN** the episode uses the file's chapters

#### Scenario: A list repeated in the notes
- **WHEN** the notes list the same chapters twice
- **THEN** the episode has each chapter once

#### Scenario: A time in prose
- **WHEN** the notes say "we recorded this at 9:30 after the show" and list no chapters
- **THEN** the episode has no chapters

### Requirement: Current chapter in Now Playing
When the episode has chapters, Now Playing SHALL show a pill under the show name with the current chapter's title and its place, such as "ג׳נסן שובב · 3 of 10". The pill MUST fill from the left in proportion to how far playback is into the chapter, and MUST follow playback as chapters change. Before the first chapter starts, and for an episode without chapters, Now Playing MUST NOT show the pill.

#### Scenario: Playing inside a chapter
- **WHEN** the episode has 10 chapters and playback is at 10:12, inside the third chapter that starts at 5:51
- **THEN** the pill reads "ג׳נסן שובב · 3 of 10"

#### Scenario: Pill fills with the chapter
- **WHEN** the third chapter runs from 5:51 to 20:25 and playback is at 10:12
- **THEN** about 30% of the pill is filled

#### Scenario: Next chapter starts
- **WHEN** playback reaches 20:25, where the fourth chapter starts
- **THEN** the pill shows the fourth chapter's title and "4 of 10", and its fill starts again from empty

#### Scenario: No chapters
- **WHEN** the episode has no chapters
- **THEN** Now Playing shows no pill and looks as it did before chapters

### Requirement: Chapter list
Tapping the pill SHALL open a sheet listing every chapter with its start time. Each row MUST show its progress: played chapters fully filled in a faint shade and dimmed, the playing chapter marked, filled in proportion and showing the time left in it, and upcoming chapters empty. Tapping a chapter SHALL jump to its start, keep the play or pause state, and close the sheet.

#### Scenario: Rows show progress
- **WHEN** the listener opens the list at 10:12, inside the third chapter that ends at 20:25
- **THEN** the first two rows are fully filled and dimmed, the third is about 30% filled and says "11 min left" (10:13 left, rounded up), and the rest are empty

#### Scenario: Jump to a chapter
- **WHEN** the listener opens the list while playing and taps the chapter that starts at 33:17
- **THEN** playback continues from 33:17, the sheet closes, and the pill shows that chapter

#### Scenario: Jump while paused
- **WHEN** the episode is paused and the listener taps a chapter in the list
- **THEN** the position moves to that chapter's start and the episode stays paused

### Requirement: Chapter art
When the playing chapter has its own picture in the audio file, Now Playing SHALL show that picture in place of the show's artwork, and SHALL show the show's artwork again when a chapter without a picture plays.

#### Scenario: Chapter with a picture
- **WHEN** playback enters a chapter whose file entry has a picture
- **THEN** Now Playing shows that picture as the artwork

#### Scenario: Chapter without a picture
- **WHEN** playback moves on to a chapter without a picture
- **THEN** Now Playing shows the show's artwork
