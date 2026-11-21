## Purpose

Lets the listener share audio files and Apple Podcasts episode links from other apps into Casterr, where they play next in the Queue.

## ADDED Requirements

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
