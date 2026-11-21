# Design

## Context

`Player` (CasterrCore) starts an episode from `EpisodeInfo`, which carries the feed's description as `summary` (raw HTML from the feed). `AVPlayerEngine` (app) loads each episode into an `AVPlayerItem` and already runs work once the item is ready, where it attaches the Back a Beat tap. Now Playing shows artwork through `ArtworkView` (by URL), the title, the show name, the scrubber, and a row of round controls. Speed's sheet is the pattern for a small sheet over Now Playing.

A quick test on the Mac confirmed that AVFoundation reads ID3 chapters in MP3s, local and streamed, but only for the locale it reports in `availableChapterLocales` (often "und"). Asking with `bestMatchingPreferredLanguages: ["en"]` returned no chapters.

## Goals / Non-Goals

**Goals:**
- One `[Chapter]` per playing episode, whichever source it came from, so the screens don't care where chapters came from.
- A show-notes parser that is strict enough never to turn prose into chapters.

**Non-Goals:**
- Storing chapters. They're derived from the feed and the file each time an episode starts, so there's nothing to sync.

## Decisions

**`Chapter` value type in CasterrCore:** `start: TimeInterval`, `title: String`, and `artwork: Data?` (image bytes from the file, nil for show-notes chapters). It's an immutable value, `Equatable` and `Sendable`.

**Show-notes parser as a pure function:** `ShowNotesChapters.parse(_ notes: String, duration: TimeInterval?) -> [Chapter]`.
- It splits the HTML into lines at `<br>`, `</p>`, `</li>` and newlines, then strips tags and decodes the common entities, like `ShowInfo.plainSummary` does (reuse that cleanup).
- A line counts only when it starts with a time: `H:MM:SS`, `HH:MM:SS`, `M:SS` or `MM:SS`, optionally inside `()` or `[]`. A separator may follow (space, `-`, `–`, `—`, `:`, `|`), then a non-empty title.
- It keeps entries in order and drops any entry whose time isn't later than the previous kept one. That removes a repeated list, as וויקלי סינק has.
- The result counts only with at least 2 chapters, and only when every time is before the duration, when the duration is known. Otherwise it returns an empty list.
- Rejected: matching times anywhere in the text. Show notes mention times in prose and in dates ("09:00:00 -0000"), which would make false chapters.

**File chapters through the engine:** `AudioEngine` gains `var onChapters: (([Chapter]) -> Void)?`. When the item is ready, `AVPlayerEngine` loads `availableChapterLocales`, asks `loadChapterMetadataGroups(withTitleLocale:containingItemsWithCommonKeys: [.commonKeyArtwork])` for the first locale, and maps each group to a `Chapter`: the start from its time range, the title from `commonIdentifierTitle`, and the artwork data from `commonIdentifierArtwork`. It calls `onChapters` only when there is at least one chapter, and only for the current item. Tests use `FakeEngine`.
- Rejected: parsing ID3 `CHAP` frames ourselves. Apple's player already does it, for streams too.

**Player:** `public private(set) var chapters: [Chapter]`, set from the show notes when an episode starts and replaced by the file's chapters if `onChapters` arrives for that episode. `currentChapter` is the last chapter whose start is at or before `position`, and nil before the first chapter. `jump(to: Chapter)` calls `seek(to:)`, so the play or pause state stays as it was.

**Chapter progress:** CasterrCore gets one pure helper: for a position, each chapter's fraction played (1 for earlier chapters, 0 for later ones, and the share between start and end for the playing one) and the playing chapter's time left. A chapter ends where the next one starts, and the last one ends at the episode's duration. With no known duration, the last chapter shows no fill and no time left. Time left is in episode time, like the scrubber's remaining time, rounded up to whole minutes ("10 min left", never "0 min left").

**Now Playing:** a `ChapterPill` under the show name, shown only when `player.currentChapter` exists. It has the title, then "· N of M", and a chevron, over a fill a shade lighter than the pill that grows from the left with the chapter's fraction played. The title uses its natural direction, so Hebrew reads right to left. VoiceOver reads "Chapter 3 of 10, ג׳נסן שובב" with the hint "Shows all chapters". Tapping it opens `ChapterList`, a sheet like speed's: rows of start time and title, each with its fraction played as a background fill from the left. Played rows are fully filled in a faint shade with secondary text. The playing row is marked with the `speaker.wave.2.fill` symbol, filled partway in tangerine, and shows its time left. Upcoming rows are empty. The fill runs left to right like the scrubber, whatever the title's direction. A tap jumps to that chapter and closes the sheet. The sheet scrolls to the playing chapter when it opens.

**Chapter art:** Now Playing shows `Image(uiImage:)` from `currentChapter.artwork` when it decodes. Otherwise it shows `ArtworkView` with the show's URL. The background tint keeps following the show's art, so the colors don't flicker when chapters change.

## Risks / Trade-offs

- [Unusual show-notes formats, such as times at the end of lines, are missed] → Those episodes have no chapters, which is today's behavior. The parser's tests document what's accepted.
- [Chapters arrive a moment after playback starts, once the item is ready] → The pill appears when they do. Show-notes chapters are there immediately.
- [Large chapter pictures in memory] → Only one episode's chapters are kept at a time, and only while it plays.
- [A streamed MP3 that only has chapter frames late in the file] → AVFoundation reads the ID3 tag at the start, where chapters normally live. Late tags give no file chapters, and the show notes are the fallback.
