# playback Specification

## Purpose
Plays podcast audio reliably: streaming from the publisher, in the background, with system controls, adjustable speed, skip intervals, a sleep timer, and progress that is never lost.

## Requirements

### Requirement: Stream episode audio
The system SHALL play a downloaded episode from its file on the phone. The system SHALL play any other episode by streaming its audio URL from the publisher. Streaming MUST start without downloading the whole file first.

#### Scenario: Play a streamed episode
- **WHEN** the listener plays an episode that isn't downloaded while online
- **THEN** audio starts playing from the episode's saved position

#### Scenario: Play a downloaded episode offline
- **WHEN** the listener plays a downloaded episode and the device has no network connection
- **THEN** audio starts playing from the episode's saved position

#### Scenario: Offline
- **WHEN** the listener plays an episode that isn't downloaded and the device has no network connection
- **THEN** the system tells the listener that the episode cannot be streamed offline

#### Scenario: Audio URL fails
- **WHEN** the audio URL returns an error
- **THEN** playback stops, the system tells the listener that the episode could not be played, and the Queue is unchanged

### Requirement: Background audio and interruptions
Playback SHALL continue when the app is in the background or the device is locked. The system MUST pause for interruptions such as phone calls and resume when the interruption ends, if the system allows it.

#### Scenario: Lock the phone
- **WHEN** the listener locks the device during playback
- **THEN** audio keeps playing

#### Scenario: Phone call
- **WHEN** a phone call interrupts playback and then ends
- **THEN** playback pauses during the call and resumes afterward when the system indicates that it should resume

#### Scenario: Headphones unplugged
- **WHEN** the audio route changes because headphones are disconnected
- **THEN** playback pauses

### Requirement: System playback controls
The system SHALL show the Now Playing episode on the lock screen and in Control Center with its title, show, artwork, elapsed time, and duration. The system SHALL respond to play, pause, skip forward, skip back, and seek commands from those controls and from headphones.

#### Scenario: Lock screen controls
- **WHEN** the listener taps skip forward on the lock screen
- **THEN** playback jumps forward 30 seconds

#### Scenario: Seek from Control Center
- **WHEN** the listener drags the progress bar in Control Center
- **THEN** playback continues from the chosen position

### Requirement: Playback speed
The system SHALL let the listener set playback speed from 1x to 2x in steps of 0.1x. Speech MUST keep its natural pitch at every speed.

#### Scenario: Change speed
- **WHEN** the listener sets speed to 1.5x
- **THEN** the episode plays 1.5 times faster and voices keep their natural pitch

#### Scenario: Speed changes while playing
- **WHEN** the listener drags the speed from 1.0x to 2.0x while an episode plays
- **THEN** the elapsed time keeps advancing at the new speed, with no freeze

### Requirement: Speed default and per-show override
Speed SHALL have a global default of 1.0x, which the listener sets in Settings. The system SHALL let the listener override speed for each show from Now Playing. A show without an override MUST follow the global default, including after the global default changes. Now Playing MUST NOT change the global default.

#### Scenario: Show without an override
- **WHEN** the global speed is 1.3x and a show has no override
- **THEN** that show's episodes play at 1.3x

#### Scenario: Show with an override
- **WHEN** a show overrides speed to 1.0x and the global speed is 1.3x
- **THEN** that show's episodes play at 1.0x

#### Scenario: Global default changes
- **WHEN** the listener changes the global speed from 1.3x to 1.5x
- **THEN** every show without an override plays at 1.5x and shows with an override are unchanged

#### Scenario: Reset an override
- **WHEN** the listener resets a show's speed override
- **THEN** that show follows the global speed again

#### Scenario: Own speed from Now Playing
- **WHEN** the listener opens speed in Now Playing and drags the slider to 1.3x
- **THEN** the episode plays at 1.3x right away, with no Done button, "Use my default" turns off by itself, and other shows keep the default

#### Scenario: Follow the default again
- **WHEN** the listener turns "Use my default" back on
- **THEN** the show's override is reset, the slider moves to the default speed, and the episode plays at it

#### Scenario: Default speed on purpose
- **WHEN** the show plays at the default 1.0x and the listener turns "Use my default" off
- **THEN** the show keeps 1.0x as its own speed, and a later change of the default doesn't move it

### Requirement: Skip intervals
The system SHALL provide skip forward by 30 seconds and skip back by 15 seconds. The intervals are the same in the app, on the lock screen, and from headphones, and they are not configurable.

#### Scenario: Skip back
- **WHEN** the listener taps skip back
- **THEN** playback moves 15 seconds earlier, or to the start if less than 15 seconds have played

#### Scenario: Skip forward near the end
- **WHEN** the listener taps skip forward with less than 30 seconds remaining
- **THEN** playback moves to the end of the episode

### Requirement: Sleep timer
The system SHALL let the listener set a sleep timer for a fixed duration, the end of the current chapter, or the end of the current episode. When the timer ends, playback MUST pause. While a timer runs, the sleep timer button in Now Playing SHALL show the time left, "Chapter" for the end of the chapter, or "End" for the end of the episode.

#### Scenario: Timer for a duration
- **WHEN** the listener sets a 15-minute sleep timer
- **THEN** playback pauses 15 minutes later

#### Scenario: End of episode
- **WHEN** the listener sets the timer to the end of the current episode
- **THEN** playback pauses when that episode ends and the next Queue item does not start

#### Scenario: Cancel
- **WHEN** the listener cancels an active sleep timer
- **THEN** playback continues without pausing

#### Scenario: Time left
- **WHEN** a 30-minute timer has run for 6 minutes
- **THEN** the sleep timer button shows 24:00 and counts down

#### Scenario: End of chapter
- **WHEN** the episode has chapters and the listener picks "This chapter" with 3 minutes left in it
- **THEN** playback pauses when the next chapter starts, and the button shows "Chapter" until then

#### Scenario: Last chapter
- **WHEN** the listener picks "This chapter" during the episode's last chapter
- **THEN** playback pauses when the episode ends, and the next Queue item does not start

#### Scenario: Seek to another chapter
- **WHEN** the chapter timer runs and the listener seeks into a later chapter
- **THEN** playback pauses at the end of the chapter it landed in

### Requirement: Saved progress
The system SHALL save each episode's playback position so that playback resumes where the listener stopped, or up to 5 seconds before it when Back a Beat finds a quiet gap. A crash or force quit MUST lose no more than a few seconds of progress. After a drag on the Now Playing slider, playback and saved progress MUST continue from where the thumb stopped.

#### Scenario: Resume after pause
- **WHEN** the listener pauses an episode at 23:10 and plays it again later
- **THEN** playback resumes at 23:10, or at a quiet gap between 23:05 and 23:08

#### Scenario: App terminated during playback
- **WHEN** the app is terminated while playing at 41:00
- **THEN** the next time the episode plays, it resumes within a few seconds of 41:00

#### Scenario: Switch episodes
- **WHEN** the listener plays a different episode while one is partly played
- **THEN** the first episode keeps its position for later

#### Scenario: Pause right after dragging the slider
- **WHEN** the listener drags a streamed episode's slider from 0:05 to 48:00 and pauses right away
- **THEN** Now Playing shows 48:00, the saved progress is 48:00, and Share Clip opens around 48:00

### Requirement: Show name opens the show page
Tapping the show name in Now Playing SHALL close Now Playing and open that show's page in the Shows tab.

#### Scenario: Open the show
- **WHEN** the listener taps "Pocket Economics" in Now Playing
- **THEN** Now Playing closes and the Shows tab shows the Pocket Economics page

### Requirement: Back a Beat
When the listener plays again after pausing, the system SHALL resume inside the latest quiet gap reaching into 2 s to 5 s before where speech stopped: the pause point, or where the quiet it fell in began. Quiet MUST be judged against the stretch's louder parts. With no gap or no audio, it MUST resume at the pause point, never before 0:00. It SHALL NOT apply after a seek or skip while paused, a second pause, or a new episode. It SHALL work for downloaded and streamed episodes.

#### Scenario: Resume at a gap
- **WHEN** the listener pauses at 23:10 and the audio is quiet from 23:06.9 to 23:07.1
- **THEN** pressing play resumes at that gap, about 23:07

#### Scenario: Latest gap wins
- **WHEN** the stretch from 23:05 to 23:08 has quiet gaps at 23:05.5 and 23:07.4
- **THEN** pressing play resumes at the 23:07.4 gap

#### Scenario: No quiet gap
- **WHEN** music plays under the voices and nothing from 23:05 to 23:08 is quiet enough
- **THEN** pressing play resumes at 23:10

#### Scenario: Interruption
- **WHEN** a phone call pauses playback and the system resumes it afterward
- **THEN** playback resumes at the latest quiet gap before the pause point

#### Scenario: Seek while paused
- **WHEN** the listener pauses, moves the position to 30:00, and presses play
- **THEN** playback resumes at 30:00

#### Scenario: Near the start
- **WHEN** the listener pauses 1 second into an episode
- **THEN** playback resumes at the pause point or later, never before 0:00

#### Scenario: Pause inside a gap
- **WHEN** the speaker stops at 23:07.4, the listener pauses at 23:10 during the silence, and the audio is quiet from 23:04.9 to 23:05.1
- **THEN** pressing play resumes at that earlier gap, about 23:05, not in the silence they paused in

#### Scenario: Gap across the window edge
- **WHEN** the listener pauses at 23:10 and the audio is quiet from 23:07.9 to 23:08.1
- **THEN** pressing play resumes at that gap, because its middle is 2 s before the pause

#### Scenario: Slow speaker
- **WHEN** pauses between words fill most of the stretch before the pause point
- **THEN** pressing play still resumes at the latest of those gaps

#### Scenario: Second pause after a seek
- **WHEN** the listener pauses, moves the position to 30:00, unplugs the headphones, and presses play
- **THEN** playback resumes at 30:00

### Requirement: Chapter sources
The system SHALL take an episode's chapters from its audio file, for downloaded and streamed episodes. When the file has none, it SHALL take them from a timestamp list in the episode's show notes: lines that start with a time, with at least two times in increasing order. Times in running prose MUST NOT become chapters. When neither source has chapters, the episode has none.

#### Scenario: Chapters in the file
- **WHEN** an episode's audio file has 12 embedded chapters
- **THEN** the episode has those 12 chapters with their titles and start times

#### Scenario: Chapters in the show notes
- **WHEN** an episode's file has no chapters and its notes list "0:00 פתיחה", "2:30 וויקלי סינק", and "5:51 ג׳נסן שובב" on separate lines
- **THEN** the episode has 3 chapters starting at 0:00, 2:30, and 5:51

#### Scenario: The file wins
- **WHEN** an episode has chapters in both its file and its notes
- **THEN** the episode uses the file's chapters

#### Scenario: A list repeated in the notes
- **WHEN** the notes list the same chapters twice
- **THEN** the episode has each chapter once

#### Scenario: A time in prose
- **WHEN** the notes say "we recorded this at 9:30 after the show" and list no chapters
- **THEN** the episode has no chapters

### Requirement: Current chapter in Now Playing
When the episode has chapters, Now Playing SHALL show a pill under the show name with the current chapter's title and its place, such as "ג׳נסן שובב · 3 of 10". The pill MUST fill from the left in proportion to how far playback is into the chapter, and MUST follow playback as chapters change. Before the first chapter starts, and for an episode without chapters, Now Playing MUST NOT show the pill.

#### Scenario: Playing inside a chapter
- **WHEN** the episode has 10 chapters and playback is at 10:12, inside the third chapter that starts at 5:51
- **THEN** the pill reads "ג׳נסן שובב · 3 of 10"

#### Scenario: Pill fills with the chapter
- **WHEN** the third chapter runs from 5:51 to 20:25 and playback is at 10:12
- **THEN** about 30% of the pill is filled

#### Scenario: Next chapter starts
- **WHEN** playback reaches 20:25, where the fourth chapter starts
- **THEN** the pill shows the fourth chapter's title and "4 of 10", and its fill starts again from empty

#### Scenario: No chapters
- **WHEN** the episode has no chapters
- **THEN** Now Playing shows no pill and looks as it did before chapters

### Requirement: Chapter list
Tapping the pill SHALL open a sheet listing every chapter with its start time. Each row MUST show its progress: played chapters fully filled in a faint shade and dimmed, the playing chapter marked, filled in proportion and showing the time left in it, and upcoming chapters empty. Tapping a chapter SHALL jump to its start, keep the play or pause state, and close the sheet.

#### Scenario: Rows show progress
- **WHEN** the listener opens the list at 10:12, inside the third chapter that ends at 20:25
- **THEN** the first two rows are fully filled and dimmed, the third is about 30% filled and says "11 min left" (10:13 left, rounded up), and the rest are empty

#### Scenario: Jump to a chapter
- **WHEN** the listener opens the list while playing and taps the chapter that starts at 33:17
- **THEN** playback continues from 33:17, the sheet closes, and the pill shows that chapter

#### Scenario: Jump while paused
- **WHEN** the episode is paused and the listener taps a chapter in the list
- **THEN** the position moves to that chapter's start and the episode stays paused

### Requirement: Chapter art
When the playing chapter has its own picture in the audio file, Now Playing SHALL show that picture in place of the show's artwork, and SHALL show the show's artwork again when a chapter without a picture plays.

#### Scenario: Chapter with a picture
- **WHEN** playback enters a chapter whose file entry has a picture
- **THEN** Now Playing shows that picture as the artwork

#### Scenario: Chapter without a picture
- **WHEN** playback moves on to a chapter without a picture
- **THEN** Now Playing shows the show's artwork

### Requirement: Voice boost
While voice boost is on, the system SHALL even out loud and quiet voices: it turns loud passages down and raises the whole level, so quiet voices come up and loud ones come down. Turning it on or off MUST take effect right away while playing, with no pause, skip, or change of position. It SHALL work for downloaded and streamed episodes. Back a Beat MUST judge quiet gaps from the audio before the boost.

#### Scenario: Quiet caller
- **WHEN** voice boost is on and a caller is much quieter than the host
- **THEN** the caller and the host play at closer loudness than with boost off

#### Scenario: Switch while playing
- **WHEN** the listener turns voice boost on at 12:30 while an episode plays
- **THEN** the boost is heard right away and playback continues from 12:30 without a pause

#### Scenario: Streamed episode
- **WHEN** voice boost is on and the listener streams an episode that isn't downloaded
- **THEN** the episode plays with the boost

#### Scenario: Back a Beat with boost on
- **WHEN** voice boost is on and the listener pauses and plays again
- **THEN** playback resumes at the same gap it would with boost off

#### Scenario: Boost can't start
- **WHEN** voice boost is on but the system can't process an episode's audio
- **THEN** the episode plays without the boost

### Requirement: Voice boost default and per-show override
Voice boost SHALL have a global default, off until the listener turns it on in Settings. The listener SHALL be able to turn it on or off for each show from Now Playing. A show without its own choice MUST follow the global default, including after the default changes. Now Playing MUST NOT change the global default.

#### Scenario: Show follows the default
- **WHEN** the global default is on and a show has no choice of its own
- **THEN** that show's episodes play with voice boost

#### Scenario: Show with its own choice
- **WHEN** a show is set to off and the global default is on
- **THEN** that show's episodes play without voice boost

#### Scenario: Global default changes
- **WHEN** the listener turns the global default on
- **THEN** every show without its own choice plays with voice boost, and shows with their own choice are unchanged

### Requirement: Voice boost in Now Playing
Now Playing SHALL show a round voice boost button with a waveform symbol, white while boost is on for the playing episode. Tapping it MUST open the voice boost sheet, with On and Off and a "Use my default" switch that shows the default. Picking On or Off MUST set the show's own choice and turn the switch off. Turning the switch on MUST remove the show's own choice. A choice applies right away, with no Done button.

#### Scenario: Turn it on for a show
- **WHEN** the default is off and the listener picks On in the sheet
- **THEN** the episode plays with voice boost right away, "Use my default" turns off, the button turns white, and other shows keep the default

#### Scenario: Follow the default again
- **WHEN** a show is set to on, the default is off, and the listener turns "Use my default" on
- **THEN** the show's own choice is removed, the boost stops, Off is picked, and the button turns back from white

#### Scenario: Menu shows the default
- **WHEN** the global default is on and the listener opens the voice boost sheet
- **THEN** the switch reads "Use my default" with "On, from Settings" under it

### Requirement: Now Playing control sheets
Speed, voice boost and the sleep timer in Now Playing SHALL each open a sheet of the same shape and height: the name and current value on top, a one-line description for voice boost and the sleep timer, then the control. Speed and voice boost SHALL end with a "Use my default" switch showing the default "from Settings", with no footer text. Every change MUST apply right away, with no Done button.

#### Scenario: Same shape
- **WHEN** the listener opens the speed sheet, then the voice boost sheet, then the sleep timer sheet
- **THEN** each has its name and value on top and the same height

### Requirement: Sleep timer sheet
The sleep timer sheet SHALL offer 15, 30, 45 and 60 minutes, "This chapter" with the minutes left in the chapter, and "End of episode" with the minutes left in the episode. "This chapter" MUST show only when the episode has chapters. While a timer runs, its choice MUST be marked, the value on top MUST show the time left, and a Turn Off button MUST show. Picking a choice MUST start it, replacing any running timer, and close the sheet.

#### Scenario: No chapters
- **WHEN** the listener opens the sleep timer sheet on an episode without chapters
- **THEN** it offers the four durations and "End of episode", without "This chapter"

#### Scenario: Turn off
- **WHEN** a 30-minute timer runs and the listener taps Turn Off
- **THEN** the timer stops and the button under the play controls loses its time

### Requirement: Headphone and car buttons
The system SHALL answer the next and previous commands, which AirPods send for a double and a triple press and other headphones and cars send from their next and previous buttons, with the action chosen in Settings: skip forward 30, skip back 15, or bookmark. A bookmark MUST save like the Now Playing Bookmark, keep playing, and play a short chime, also with silent mode on. The lock screen MUST keep its 15 and 30 buttons.

#### Scenario: Double press with the defaults
- **WHEN** an episode plays at 12:34 and the listener double presses an AirPod
- **THEN** a bookmark at 12:34 is saved, a chime plays over the episode, and playback continues

#### Scenario: Triple press with the defaults
- **WHEN** the listener triple presses an AirPod
- **THEN** playback moves 15 seconds earlier

#### Scenario: Silent mode
- **WHEN** silent mode is on and the listener bookmarks with a double press
- **THEN** the chime still plays

#### Scenario: Car buttons
- **WHEN** the listener presses next on the car's steering wheel with double press set to Skip forward 30
- **THEN** playback moves 30 seconds later

#### Scenario: Lock screen
- **WHEN** the listener looks at the lock screen while an episode plays
- **THEN** it shows the skip back 15 and skip forward 30 buttons, not next and previous track

#### Scenario: Nothing loaded
- **WHEN** no episode is loaded and a next or previous command arrives
- **THEN** nothing is saved and no chime plays
