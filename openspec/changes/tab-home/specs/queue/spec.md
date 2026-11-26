## ADDED Requirements

### Requirement: Tab taps
A tap on the Queue tab SHALL open the Queue, whichever page under the Queue the listener left open. A tap on the Shows or Bookmarks tab from another tab SHALL open the page the listener left in that tab. A tap on the tab that is already open SHALL go back to that tab's main page: the Queue, the Shows grid, or the Bookmarks list. Pages that the app opens by itself, such as the Inbox from the refresh message, MUST still open.

#### Scenario: Back to the Queue from another tab
- **WHEN** the listener opens the Inbox, taps the Shows tab, then taps the Queue tab
- **THEN** the Queue shows, not the Inbox

#### Scenario: Shows keeps its place
- **WHEN** the listener opens a show page in Shows, taps the Queue tab, then taps the Shows tab
- **THEN** the same show page shows

#### Scenario: Second tap on the open tab
- **WHEN** the listener is on a show page in Shows and taps the Shows tab
- **THEN** the Shows grid shows

#### Scenario: Second tap on Queue
- **WHEN** the listener is in the Inbox and taps the Queue tab
- **THEN** the Queue shows

#### Scenario: Refresh message opens the Inbox
- **WHEN** the listener taps the refresh message while on the Shows tab
- **THEN** the Inbox opens in the Queue tab
