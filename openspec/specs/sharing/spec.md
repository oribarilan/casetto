# sharing Specification

## Purpose
Lets the listener share audio files and Apple Podcasts episode links from other apps into Casterr, where they play next in the Queue.

## Requirements

### Requirement: Share to Casterr
Casterr SHALL appear in other apps' share sheets for audio files and web links. A shared audio file or Apple Podcasts episode link SHALL go next in the Queue like Play next: after Now Playing and earlier Play next episodes, or first in an empty Queue. It MUST arrive when the app next opens or comes to the front, and within a few seconds when the app is running. Of several files, the system SHALL take the first audio file.

#### Scenario: Share while Casterr is closed
- **WHEN** the Queue is empty and the listener shares an MP3 from Files, then opens Casterr
- **THEN** the episode is first in the Queue

#### Scenario: Share while Casterr is playing in the background
- **WHEN** Casterr is playing and the listener shares an M4A from WhatsApp
- **THEN** within a few seconds the shared episode is second in the Queue, right after the playing episode, which keeps playing

### Requirement: Shared audio files
For a shared audio file, the system SHALL keep its own copy on the device. The episode's title MUST come from the file's title tag, or else from the file name without its extension. Every shared file MUST show Cassy as its art. A shared file MUST stay until the listener deletes it, including after it's played. Voice notes from WhatsApp and Telegram (Ogg Opus) count as audio files.

#### Scenario: File with tags
- **WHEN** the listener shares an MP3 whose title tag is "Interview with Dana"
- **THEN** the episode is called "Interview with Dana" and shows Cassy

#### Scenario: File without tags
- **WHEN** the listener shares "Voice memo 12.m4a" with no tags
- **THEN** the episode is called "Voice memo 12" and shows Cassy

#### Scenario: Played file stays
- **WHEN** a shared file plays to the end
- **THEN** the file stays on the device and stays listed on the Shared with Casterr page

### Requirement: Shared with Casterr show
Shared files SHALL belong to a built-in show called "Shared with Casterr". It MUST appear in the Shows grid once a file has been shared, and its page MUST list every shared file, newest first. Deleting one on that page MUST delete the file and remove the episode from wherever it is. The show MUST NOT offer following, unfollowing, or new-episode settings, and MUST NOT refresh.

#### Scenario: First shared file
- **WHEN** the listener shares their first audio file
- **THEN** "Shared with Casterr" appears in the Shows grid

#### Scenario: Delete a shared file
- **WHEN** the listener deletes a shared file that is second in the Queue
- **THEN** the file is gone from the device, the episode leaves the Queue and the show's page, and the other Queue items keep their order

### Requirement: Shared Apple Podcasts links
For a shared Apple Podcasts episode link, the system SHALL find the show's feed and that episode through Apple's lookup, and put the episode next in the Queue without following the show. When a followed show already has an episode with the same GUID, the system MUST use that episode. When the episode can't be found, nothing MUST change.

#### Scenario: Episode of a show you don't follow
- **WHEN** the listener shares a link to an ATP episode and doesn't follow ATP
- **THEN** that episode plays next and ATP stays unfollowed

#### Scenario: Episode of a show you follow
- **WHEN** the listener follows ATP through a different feed address and shares a link to one of its episodes
- **THEN** the episode they already have moves to play next, with no duplicate show or episode

#### Scenario: Episode not found
- **WHEN** the shared link points to an episode Apple's lookup doesn't list
- **THEN** the Queue doesn't change and the confirmation says the episode wasn't found

### Requirement: Share confirmation
After a share, the extension SHALL show a card with Cassy. When the item was accepted, the card MUST say "Up next in your Queue" with the episode's title (the file's title tag or file name, or the episode's title from Apple) and close by itself after about 1.5 seconds. When it wasn't, the card MUST say why and stay until the listener taps Done.

#### Scenario: Accepted
- **WHEN** the listener shares "Voice memo 12.m4a"
- **THEN** the card shows "Up next in your Queue" and "Voice memo 12", then closes by itself

#### Scenario: Not something Casterr takes
- **WHEN** the listener shares a link to a news article
- **THEN** the card says Casterr takes audio files and Apple Podcasts episode links, and stays until Done

#### Scenario: Audio Casterr can't play
- **WHEN** the listener shares an audio file Apple's player can't play
- **THEN** the card says Casterr can't play that kind of file, nothing is queued, and the card stays until Done

#### Scenario: Offline link
- **WHEN** the listener shares an Apple Podcasts link with no connection
- **THEN** the card says Casterr couldn't reach Apple Podcasts and stays until Done

### Requirement: Shared episodes stay on this phone
Shared files SHALL exist only on the device they were shared to. Other devices MUST NOT show them in the Queue or the Shows grid. A bookmark on a shared file syncs, and on a device without the file its play button MUST be disabled.

#### Scenario: Another device
- **WHEN** the listener shares a file on their phone and opens Casterr on their iPad
- **THEN** the iPad's Queue and Shows grid don't show it

#### Scenario: Bookmark on a shared file
- **WHEN** the listener bookmarks a shared file on their phone and opens Bookmarks on their iPad
- **THEN** the bookmark and its note show on the iPad with its play button disabled

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

### Requirement: Share a show
The show page SHALL let the listener share the show: its name and its Podlink page, built from its feed address. The built-in Shared with Casterr show MUST NOT offer it.

#### Scenario: Show with a web page
- **WHEN** the listener shares Planet Money from its page
- **THEN** the message is "Planet Money" with a `https://pod.link/…` link to the show

### Requirement: Clip editor
"Share Clip" in Now Playing SHALL open an editor that shows the two minutes around the current time as loudness bars, with a clip framed from 15 seconds before now to 15 seconds after, kept within the episode. The listener MUST be able to drag either edge, for a clip of 5 to 60 seconds, and preview it at normal speed, as it will be sent. Previewing MUST pause the episode.

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
Share in the clip editor SHALL make a square video of the art Now Playing shows, sharp at full size, with the Casterr badge, the clip's waveform along the bottom filling tangerine as it plays, and the clip's audio, and open the share sheet with "Episode – Show" and the Podlink link. The clip MUST come from what the player plays. A streamed episode MUST fetch only the part it needs; when that can't work, the editor MUST say to download it, and offline say so.

#### Scenario: Downloaded episode
- **WHEN** the listener shares a 30-second clip of a downloaded episode
- **THEN** a square video with the show's sharp art, the "Clipped with Casterr" badge, the clip's waveform filling left to right, and that audio opens in the share sheet, with "Episode – Show" and the episode's Podlink link

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
