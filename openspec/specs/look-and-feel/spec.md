# look-and-feel Specification

## Purpose
Gives Casterr its Tangerine look and a mascot, Cassy, who explains the automation in her own voice.

## Requirements

### Requirement: Tangerine look
The app SHALL use a tangerine accent in light and dark appearance, heavy rounded large titles, and rounded type for text.

#### Scenario: Dark mode
- **WHEN** the device is in dark mode
- **THEN** the accent is the lighter tangerine and text on it stays readable

### Requirement: Show art
Episode rows in the Queue, Inbox, and show page SHALL show their show's artwork. The Shows tab SHALL show followed shows as a grid of artwork with titles. The show page SHALL open with a large artwork header. The mini player SHALL show the current show's artwork. A show without artwork MUST show a placeholder with its first letter.

#### Scenario: Shows grid
- **WHEN** the listener follows 9 shows
- **THEN** the Shows tab shows a grid of 9 artwork tiles with titles, marking Auto-queue and Play Next shows with a star and failing feeds with a warning

#### Scenario: No artwork
- **WHEN** a feed has no artwork
- **THEN** its rows and tile show a tangerine placeholder with the show's first letter

### Requirement: Now Playing tint
Now Playing SHALL use a background color taken from the show's artwork, darkened enough for white text to stay readable. Now Playing SHALL show the standard iOS grab handle at its top, so the listener can see it swipes down to close.

#### Scenario: Tinted background
- **WHEN** an episode with mostly green artwork is playing
- **THEN** Now Playing has a dark green background with white text

#### Scenario: Grab handle
- **WHEN** the listener opens Now Playing
- **THEN** a grab handle shows at the top of the sheet

### Requirement: Idle loops
When Cassy has no job to show, she SHALL play one of eight idle loops (blink, wink, look around, breathe, reel twitch, hum, yawn, peek) at random, 0.7 to 1.2 seconds after appearing and then 0.7 to 1.2 seconds after each loop ends, never the same loop twice in a row, so she moves most of the time. Reduce Motion MUST stop the loops.

#### Scenario: Rule card avatar
- **WHEN** a rule card stays on screen for a minute
- **THEN** Cassy plays many different loops with pauses of at most 1.2 seconds between them

#### Scenario: Welcome screen
- **WHEN** the welcome screen appears
- **THEN** Cassy starts a loop within 1.2 seconds and is moving most of the time she's on screen

### Requirement: Cassy's moods
Cassy SHALL appear as a sticker-style cassette in three functional moods: dozing, cheering, and dizzy. Her animations MUST stay still when Reduce Motion is on. Now Playing MUST NOT show Cassy, so the show's artwork leads there.

#### Scenario: Empty Queue
- **WHEN** the Queue is empty
- **THEN** Cassy dozes above the empty-state message and its Find shows button

#### Scenario: Empty Inbox
- **WHEN** the Inbox holds no episodes and no cards
- **THEN** Cassy cheers above the message "Inbox zero!"

#### Scenario: Failing feed
- **WHEN** a show's last refresh failed
- **THEN** its show page shows Cassy dizzy beside the error and when the feed last worked

### Requirement: Cassy presents rule cards
Rule cards SHALL show Cassy beside a short question with the show name in accent text and the reason underneath. The card MUST offer one accept button. A small ✕ and a swipe left MUST dismiss the card for 30 days. A "…" menu MUST hold "Never ask about this show" and, on the Ignored card, Unfollow.

#### Scenario: Auto-queue card
- **WHEN** the Auto-queue card applies to Tape Hiss
- **THEN** the card asks "Queue new Tape Hiss episodes for you?" with "You play it the day it drops." underneath and a Queue Them button

#### Scenario: Swipe to dismiss
- **WHEN** the listener swipes a card left
- **THEN** the card is gone for 30 days

### Requirement: Playback problems in Cassy's toast
When an episode can't stream offline or its audio fails, Cassy SHALL say so in her toast, on any screen, instead of as text in Now Playing.

#### Scenario: Offline
- **WHEN** the listener plays an episode that isn't downloaded while offline
- **THEN** Cassy's toast says "You're offline, and this one isn't downloaded yet."

### Requirement: Refresh summary
After a refresh started while the app is open that placed or expired episodes, Cassy SHALL show a toast summing up what moved, in her first person. Tapping it MUST open the Inbox. A refresh that moved nothing MUST NOT show a toast.

#### Scenario: Mixed refresh
- **WHEN** a refresh puts 1 episode in the Inbox, queues 1, and expires 2
- **THEN** the toast says "2 new episodes. I queued 1 and removed 2 old ones from your Inbox."

#### Scenario: Quiet refresh
- **WHEN** a refresh finds nothing new and expires nothing
- **THEN** no toast shows

### Requirement: End of the Queue
When the last Queue episode plays to its end, Cassy SHALL offer to check for new episodes. Choosing Check Now MUST refresh. The offer MUST NOT show when the end-of-episode sleep timer stopped playback.

#### Scenario: Queue runs out
- **WHEN** the only Queue episode finishes
- **THEN** Cassy says "That's the lot. Want me to check for new episodes?" with Check Now

### Requirement: Cassy in onboarding and bookmarks
Onboarding SHALL open with Cassy introducing herself and starring. The first star MUST make her cheer. The bookmark toast SHALL show Cassy cheering.

#### Scenario: First star
- **WHEN** the listener stars their first show in onboarding
- **THEN** Cassy cheers and says "Nice pick! I'll queue its new episodes."

### Requirement: One word per idea
All text in the app SHALL use one word per idea: "Remove" when an episode leaves the Inbox or Queue, by the listener or automatically; "Skip" for a show whose new episodes never enter them; "Dismiss" only for Cassy's cards and tips; and "Delete" only for bookmarks. The word "archive" MUST NOT appear in the app.

#### Scenario: Removing from the Queue
- **WHEN** the listener swipes a Queue episode left
- **THEN** the action says "Remove", not "Delete"

#### Scenario: Automatic removal
- **WHEN** an Inbox episode expires after 7 days
- **THEN** its row reads "Removed after 7 days" and the refresh summary says "removed 1 old one from your Inbox"

### Requirement: Show art on the device
Show art SHALL be kept on the device once loaded and shown from there without asking the server again, wherever it appears. It MUST show offline once it has loaded before. While art downloads, its square MUST show a soft grey shimmer, still grey with Reduce Motion, and fade into the art. Art already on the device MUST appear with no shimmer. A show with no art, or art that fails to load, MUST show the tangerine square with its first letter.

#### Scenario: Offline grid
- **WHEN** the listener follows shows whose art has loaded, then opens the Shows tab offline
- **THEN** every show's art appears

#### Scenario: No reload
- **WHEN** the listener scrolls the Shows grid away and back
- **THEN** the art appears at once, with no letter placeholder in between

#### Scenario: First download
- **WHEN** Find Shows lists a show whose art isn't on the device yet
- **THEN** its square shimmers grey until the art arrives, then fades into it

#### Scenario: No art
- **WHEN** a show's feed has no art
- **THEN** its square is tangerine with the show's first letter
