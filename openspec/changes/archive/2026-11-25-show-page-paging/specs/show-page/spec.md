## ADDED Requirements

### Requirement: Long episode lists
The show page SHALL show the newest 30 episodes of its Episodes list, then a "Show older episodes" row when more remain. Each tap MUST add the next 30 without moving what's already shown. The open Played list MUST work the same way, and its count MUST still count every played episode. Each visit to the page MUST start at 30.

#### Scenario: A long back catalog
- **WHEN** the listener opens a show with 2,787 episodes
- **THEN** the page shows the newest 30 and a "Show older episodes" row at the end

#### Scenario: Show older episodes
- **WHEN** the listener taps "Show older episodes"
- **THEN** the next 30 episodes appear below the ones already shown, and the row moves to the end again

#### Scenario: A short show
- **WHEN** a show has 12 episodes
- **THEN** all 12 show and there is no "Show older episodes" row

#### Scenario: Played list
- **WHEN** a show has 80 played episodes and the listener opens Played
- **THEN** Played (80) shows the newest 30 played episodes and a "Show older episodes" row
