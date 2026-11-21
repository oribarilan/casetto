# Proposal

## Why

Long episodes cover many topics, and listeners want to see where they are and jump to the part they care about. Many shows already publish chapters: ATP, Lex Fridman and Connected embed them in the audio file, and וויקלי סינק, Huberman and Lex list timestamps in their show notes. Casterr ignores both today.

This isn't a roadmap milestone. It's "chapters" from the "After the MVP" list and adds to the player from M1. Transcripts, the other half of that list item, stay on the list.

## What Changes

- **Where chapters come from:** the chapters embedded in the episode's audio file. When the file has none, Casterr reads a list of timestamps from the episode's show notes, such as "5:51 ג׳נסן שובב". Downloaded and streamed episodes work the same.
- **Now Playing:** when the episode has chapters, a pill under the show name shows the current chapter's title and its place, for example "ג׳נסן שובב · 3 of 10". The pill fills from the left, a shade lighter, as the chapter plays. Without chapters, Now Playing looks as it does today.
- **Chapter list:** tapping the pill opens a sheet listing every chapter with its start time. Each row is its own progress bar: played chapters are filled in a faint shade and dimmed, the playing chapter fills partway in tangerine and shows the time left in it ("10 min left"), and upcoming chapters are empty. Tapping a chapter jumps to its start and keeps playing.
- **Chapter art:** when the playing chapter has its own picture in the audio file, Now Playing shows it in place of the show art.
- The lock screen and headphone controls keep skipping 30 and 15 seconds. They don't jump between chapters.
- `podcast_app_concept.md` gets a Chapters bullet in the Player section, and the "After the MVP" item becomes just "transcripts".

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `playback`: new requirements for where chapters come from, the chapter pill, the chapter list, and chapter art.

## Out of scope

- The separate chapters file some feeds link to (Podcasting 2.0 `podcast:chapters`). None of the 11 feeds checked publishes one.
- Next and previous chapter buttons, and chapter marks on the scrubber. We add them only if the listener misses them.
- Chapter links (URLs embedded in chapters).
- Chapters on the show page or in episode rows. Chapters appear only in Now Playing.
- Chapters on the lock screen, in Control Center, or in CarPlay.
- Timestamps in an episode's `content:encoded` field. Casterr keeps only the description today.
- Making chapters with Apple's on-device model. That waits with the parked smart bookmarks.

## Impact

- `CasterrCore`: a `Chapter` value type, a pure parser that finds a timestamp list in show notes, and `Player` support: its chapters, the current chapter, and jumping to one. `AudioEngine` gains a way to report the file's chapters. Chapters aren't stored or synced, since they come from the feed and the file each time an episode starts.
- App: `AVPlayerEngine` reads the file's chapters with Apple's player once the item is ready. Now Playing gets the pill, the list sheet, and chapter art.
- **Risk:** show notes are free text. The parser accepts only a clear list (timestamps at the start of lines, at least two, in increasing order), so prose that mentions a time doesn't become a chapter.
