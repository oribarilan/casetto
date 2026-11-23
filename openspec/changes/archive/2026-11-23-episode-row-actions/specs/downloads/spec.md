## MODIFIED Requirements

### Requirement: Downloaded indicator
Every episode row in the Queue, the Inbox and on show pages SHALL say "Downloaded" in its status line when the episode's file is on the phone.

#### Scenario: Downloaded episode in the Queue
- **WHEN** a Queue episode's download is complete
- **THEN** its Queue row says "Downloaded"

#### Scenario: Downloaded episode on its show page
- **WHEN** the listener opens the show page of a downloaded Queue episode
- **THEN** its row reads "Queued · Downloaded"
