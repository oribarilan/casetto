# settings Specification

## Purpose
The one place for global defaults; everything per show stays in context.

## Requirements

### Requirement: Global defaults
The system SHALL have a Settings screen, opened from a gear on the Queue, with the global defaults: how long unplayed episodes wait in the Inbox (1d, 3d, 7d, 14d, 30d, Never), how many Queue episodes stay downloaded (Off, 1, 3, 5, 10), the default speed, and whether voice boost is on. It SHALL also hold Clear Cache. Each default SHALL say how it relates to per-show settings. A link from elsewhere MUST be able to open Settings at a section, briefly highlighted.

#### Scenario: Open from the Inbox
- **WHEN** the listener taps the expiry line in the Inbox
- **THEN** Settings opens with the Inbox section highlighted

#### Scenario: Turn downloads off
- **WHEN** the listener sets Keep downloaded to Off
- **THEN** downloaded files are deleted and no download starts

#### Scenario: Turn voice boost on
- **WHEN** the listener turns on Voice boost in the Playback section, under Default speed
- **THEN** the playing episode gets the boost right away if its show has no choice of its own, and the footer says a show can have its own from Now Playing

### Requirement: Clear cache
Settings SHALL have a Storage section with Clear Cache, showing how much space the saved show art and popular lists take. Tapping it MUST delete them, so they download again when needed, and MUST confirm with a checkmark and "Cleared" for a moment. Downloaded episodes, bookmarks, and shared files MUST stay. The section MUST also show the space downloaded episodes take, with no action.

#### Scenario: Clear the cache
- **WHEN** the listener taps Clear Cache
- **THEN** the button shows a checkmark and "Cleared", the size shown drops within a few seconds, downloaded episodes stay, and show art downloads again the next time it appears

#### Scenario: Downloads size
- **WHEN** three Queue episodes of about 70 MB each are downloaded and the listener opens Settings
- **THEN** Storage shows "Downloaded episodes" with about 210 MB, and no button to delete them

### Requirement: Download size
Under the Keep downloaded picker, Settings SHALL say how much space the current choice takes: "About 210 MB for the top 3." It MUST add up the sizes the feeds list for that many top Queue episodes, downloaded or not, and estimate an episode at 128 kbps from its length when its feed gives no plausible size. Shared files MUST NOT count. Off, or nothing to count, MUST show no line.

#### Scenario: Pick a choice
- **WHEN** the Queue starts with three episodes of 70 MB each and the listener picks 3
- **THEN** the line reads "About 210 MB for the top 3"

#### Scenario: Tap another choice
- **WHEN** the listener taps 10 with only five episodes in the Queue
- **THEN** the line adds up those five and still says "for the top 10"

#### Scenario: No size in the feed
- **WHEN** an episode's feed lists no file size and the episode is 60 minutes long
- **THEN** it counts as about 58 MB

#### Scenario: Off
- **WHEN** the listener picks Off
- **THEN** no size line shows

### Requirement: Headphone and car buttons setting
Settings SHALL have a "Headphone and car buttons" section right after Playback, with two pickers, Double press and Triple press. Each MUST offer Skip forward 30, Skip back 15, and Bookmark. The defaults MUST be Bookmark for double press and Skip back 15 for triple press. The footer MUST say what each press does now, joined into one sentence when both match, and that other headphones and cars do the same with their next and previous buttons.

#### Scenario: Defaults
- **WHEN** the listener opens Settings for the first time
- **THEN** Double press shows Bookmark, Triple press shows Skip back 15, and the footer reads "Double press bookmarks, with a chime. Triple press skips back 15. Other headphones and cars do the same with their next and previous buttons."

#### Scenario: Change a press
- **WHEN** the listener sets Triple press to Skip forward 30
- **THEN** the footer says "Triple press skips forward 30" and the next triple press skips forward

#### Scenario: Both the same
- **WHEN** the listener sets both presses to Skip forward 30
- **THEN** the footer starts with "Double and triple press skip forward 30."

#### Scenario: Another device
- **WHEN** the listener changes Double press on one iPhone signed in to the same iCloud account as another
- **THEN** the other iPhone uses the new choice after it syncs
