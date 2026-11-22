## MODIFIED Requirements

### Requirement: Share a clip
Share in the clip editor SHALL make a square video of the art Now Playing shows, with the Casterr badge and the clip's audio, and open the share sheet with the video and the episode's text and link as the caption. The clip MUST come from what the player plays. For a streamed episode, the system MUST fetch only the part it needs and decode it from its first real audio frame; when that can't work, the editor MUST say to download the episode first, and offline it MUST say so.

#### Scenario: Downloaded episode
- **WHEN** the listener shares a 30-second clip of a downloaded episode
- **THEN** a square video with the show's art, the "Clipped with Casterr" badge, and that audio opens in the share sheet, with the text and link

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
