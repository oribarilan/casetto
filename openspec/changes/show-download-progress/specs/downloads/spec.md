## MODIFIED Requirements

### Requirement: Downloaded indicator
Every episode row in the Queue, the Inbox and on show pages SHALL say "Downloaded" in its status line when the episode's file is on the phone, "Downloading" with the percent done while it downloads, and "Waiting for Wi-Fi" when it should download but the phone isn't on a network downloads may use.

#### Scenario: Downloaded episode in the Queue
- **WHEN** a Queue episode's download is complete
- **THEN** its Queue row says "Downloaded"

#### Scenario: Downloaded episode on its show page
- **WHEN** the listener opens the show page of a downloaded Queue episode
- **THEN** its row reads "Queued · Downloaded"

#### Scenario: Download in progress
- **WHEN** a Queue episode's download is 45% done
- **THEN** its row says "Downloading 45%", and the number rises as it downloads

#### Scenario: Away from Wi-Fi
- **WHEN** the phone is on cellular and the second Queue episode isn't downloaded yet
- **THEN** its row says "Waiting for Wi-Fi"
