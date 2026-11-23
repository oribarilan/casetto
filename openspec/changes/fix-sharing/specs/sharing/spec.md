## MODIFIED Requirements

### Requirement: Share an episode
The system SHALL let the listener share an episode from Now Playing and from the action line of episode rows in the Queue, the Inbox and show pages. It MUST send "Episode – Show", with no time, and the episode's Podlink link, built from the show's feed address and the episode's GUID; an episode with no GUID links to the show on Podlink. The share sheet MUST show the show's art.

#### Scenario: Episode with its own page
- **WHEN** the listener shares ATP episode 718 from its row
- **THEN** the message is "718: The Warp Zone – Accidental Tech Podcast" with a `https://pod.link/…/episode/…` link to that episode

#### Scenario: Feed without episode pages
- **WHEN** every episode in a feed links to the same show page, and the listener shares one
- **THEN** the message still carries that episode's own Podlink link

#### Scenario: From Now Playing
- **WHEN** the listener shares from Now Playing at 12:34
- **THEN** the message is "Episode – Show" with no time

#### Scenario: Shared file
- **WHEN** the listener opens the action line of a file on the Shared with Casterr page
- **THEN** no share action is offered

#### Scenario: From the Queue
- **WHEN** the listener taps Share in a Queue row's action line
- **THEN** the share sheet opens with "Episode – Show" and its link

#### Scenario: Episode with no GUID
- **WHEN** the listener shares an episode whose feed item has no GUID
- **THEN** the link is the show's Podlink page

### Requirement: Share a clip
Share in the clip editor SHALL make a square video of the art Now Playing shows, sharp at full size, with the Casterr badge and the clip's audio, and open the share sheet with the video, "Episode – Show" and the Podlink link. The clip MUST come from what the player plays. A streamed episode MUST fetch only the part it needs, decoded from its first real audio frame; when that can't work, the editor MUST say to download the episode first, and offline it MUST say so.

#### Scenario: Downloaded episode
- **WHEN** the listener shares a 30-second clip of a downloaded episode
- **THEN** a square video with the show's sharp art, the "Clipped with Casterr" badge, and that audio opens in the share sheet, with "Episode – Show" and the episode's Podlink link

#### Scenario: Streamed episode
- **WHEN** the listener opens the editor while streaming an MP3 episode
- **THEN** Casterr fetches about two minutes of the file, shows the bars, and shares the clip without downloading the episode

#### Scenario: Server can't send part of a file
- **WHEN** the episode is streamed from a server that can't send part of the file
- **THEN** the editor says "Download this episode to make a clip" and offers no Share

#### Scenario: Offline while streaming
- **WHEN** the listener opens the editor for a streamed episode with no connection
- **THEN** the editor says "You're offline. Connect to make a clip of a streamed episode." and offers no Share

#### Scenario: Fetched part starts with a fake frame
- **WHEN** the fetched part of a streamed MP3 starts with bytes that look like a frame of another format
- **THEN** the editor skips to the first real frame, shows the bars, and the clip's times match the episode

### Requirement: Share a show
The show page SHALL let the listener share the show: its name and its Podlink page, built from its feed address. The built-in Shared with Casterr show MUST NOT offer it.

#### Scenario: Show with a web page
- **WHEN** the listener shares Planet Money from its page
- **THEN** the message is "Planet Money" with a `https://pod.link/…` link to the show
