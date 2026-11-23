## MODIFIED Requirements

### Requirement: Share an episode
The system SHALL let the listener share an episode from Now Playing and from the action line of episode rows in the Queue, the Inbox and show pages. It MUST send "Episode – Show" and a link: the episode's own web page from its feed, or else its audio link. From Now Playing it MUST add the current time as text, such as "from 12:34". The share sheet MUST show the show's art.

#### Scenario: Episode with its own page
- **WHEN** the listener shares ATP episode 718 from its row
- **THEN** the message is "718: The Warp Zone – Accidental Tech Podcast" with the link `https://atp.fm/718`

#### Scenario: Feed without episode pages
- **WHEN** every episode in a feed links to the same show page, and the listener shares one
- **THEN** the message carries the episode's audio link instead

#### Scenario: From Now Playing
- **WHEN** the listener shares from Now Playing at 12:34
- **THEN** the message ends with "from 12:34"

#### Scenario: Shared file
- **WHEN** the listener opens the action line of a file on the Shared with Casterr page
- **THEN** no share action is offered

#### Scenario: From the Queue
- **WHEN** the listener taps Share in a Queue row's action line
- **THEN** the share sheet opens with "Episode – Show" and its link
