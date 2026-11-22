## ADDED Requirements

### Requirement: Share an episode
The system SHALL let the listener share an episode from Now Playing and from episode rows on show pages. It MUST send "Episode – Show" and a link: the episode's own web page from its feed, or else its audio link. From Now Playing it MUST add the current time as text, such as "from 12:34". The share sheet MUST show the show's art.

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
- **WHEN** the listener long-presses a file on the Shared with Casterr page
- **THEN** no share action is offered

### Requirement: Share a show
The show page SHALL let the listener share the show: its name and its web page from the feed, or else its feed address. The built-in Shared with Casterr show MUST NOT offer it.

#### Scenario: Show with a web page
- **WHEN** the listener shares Planet Money from its page
- **THEN** the message is "Planet Money" with the show's web page

### Requirement: Clip editor
"Share Clip…" in Now Playing SHALL open an editor that shows the two minutes around the current time as loudness bars, with a clip framed from 15 seconds before now to 15 seconds after, kept within the episode. The listener MUST be able to drag either edge, for a clip of 5 to 60 seconds, and preview it at normal speed, as it will be sent. Previewing MUST pause the episode.

#### Scenario: Opens around now
- **WHEN** the listener opens the editor at 12:19
- **THEN** the bars span 11:19 to 13:19 and the clip is 12:04 to 12:34

#### Scenario: Near the start
- **WHEN** the listener opens the editor at 0:05
- **THEN** the clip starts at 0:00 and runs 30 seconds

#### Scenario: Limits
- **WHEN** the listener drags an edge to make the clip 75 seconds
- **THEN** the clip stops at 60 seconds

### Requirement: Clip edges snap to pauses
In the clip editor, an edge SHALL snap to the middle of a quiet gap between words, found the way Back a Beat finds them, when it comes within half a second of one, with a light haptic tick. Dragging further MUST free it. The default clip's edges MUST also snap to the nearest gaps when the editor opens. Where no gap is near, an edge MUST move freely.

#### Scenario: Snap while dragging
- **WHEN** the listener drags the start edge to 12:03.6 and there's a pause from 12:03.1 to 12:03.3
- **THEN** the start snaps to 12:03.2 with a tick

#### Scenario: Pull free
- **WHEN** the listener keeps dragging the start edge past the pause to 12:02.5
- **THEN** the start follows to 12:02.5

#### Scenario: Default clip snaps
- **WHEN** the editor opens at 12:19 and the nearest pauses to 12:04 and 12:34 are at 12:04.4 and 12:33.8
- **THEN** the clip is 12:04.4 to 12:33.8

#### Scenario: Music under the voices
- **WHEN** no quiet gap lies within half a second of an edge
- **THEN** the edge moves freely and doesn't snap

### Requirement: Share a clip
Share in the clip editor SHALL make a square video of the art Now Playing shows, with the Casterr badge, and the clip's audio, and open the share sheet with the video and the episode's text and link as the caption. The clip MUST come from what the player is playing. For a streamed episode, the system MUST fetch only the part it needs; when that can't work, the editor MUST say to download the episode first, and offline it MUST say so.

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

### Requirement: Clips play at normal speed
A clip SHALL play at normal speed, whatever speed the listener uses, and the editor's preview MUST play it the same way.

#### Scenario: Listening faster
- **WHEN** the listener plays at 1.5x and shares a 30-second clip
- **THEN** the clip plays at normal speed and runs 30 seconds

### Requirement: Clip badge
Every clip video SHALL show a badge in its top left corner: the app icon and "Clipped with Casterr" on a nearly opaque dark capsule, about a quarter of the video's width.

#### Scenario: Badge on the art
- **WHEN** the listener shares a clip
- **THEN** the video's top left corner shows the app icon and "Clipped with Casterr", readable over any art
