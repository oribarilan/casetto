# Design

## Context

The look comes from the [Casterr Glow-Up](https://claude.ai/code/artifact/061fffba-976f-4602-964d-47ebcb6d1d04) mockups: Tangerine, with Cassy drawn as a sticker (cream body, dark outline, hard orange shadow, small chin) and dizzy on errors. Feed records already hold each show's artwork address. The simplicity rule applies: system fonts, SwiftUI shapes, and no new dependencies.

## Decisions

### D1. Theme

- `Color.tangerine` is a dynamic color: `#FF5A1F` in light and `#FF7A45` in dark. The root view sets `.tint(.tangerine)` and `.fontDesign(.rounded)`.
- Large titles use SF Pro Rounded Black through `UINavigationBar.appearance()`, set once at launch, because SwiftUI has no modifier for the large title font.

### D2. Artwork

- `ArtworkView(url:title:size:)` wraps `AsyncImage` with a tangerine placeholder showing the title's first letter. Corners are 12 points at row size.
- `Library.showArt()` returns every show's title and artwork address in one fetch, so a list loads its art, and the placeholder letter, with one call.
- At launch the app sets `URLCache.shared` to 50 MB of memory and 300 MB of disk. `AsyncImage` loads through `URLSession.shared`, which uses that cache.

### D3. Now Playing tint

`ArtworkTint.color(of: CGImage) -> RGB` in `CasterrCore` averages the image with Core Image's `CIAreaAverage`, then caps the brightness at 35% and raises low saturation slightly, so white text keeps at least 4.5:1 contrast. Now Playing fetches the image through the shared cache, computes the tint once per show, and draws a gradient from the tint to a darker shade.

### D4. Cassy

`CassyView(mood:size:)` draws the sticker with SwiftUI shapes, the same geometry as the mockup: a body rectangle with a dark outline and an offset orange shadow, a window, the small chin, and two reels as eyes. Moods:

| Mood | Face | Motion |
|---|---|---|
| Idle | Shining eyes (round pupil with a white highlight), small smile | A random idle loop now and then (D10) |
| Dozing | Closed arcs, small "o" | Two "z"s drift up |
| Cheering | Happy arcs, open smile, sparkles | A small hop |
| Dizzy | Spiral eyes, wobbly mouth, stars | Spirals rotate |

Every animation stops when `accessibilityReduceMotion` is on. Cassy has an accessibility label naming her mood, or is hidden from VoiceOver when the text beside her says the same thing.

### D5. Cassy toast

`AppModel.cassyToast` holds a mood, a line, and an optional action. A `cassyToast()` modifier, like the bookmark toast, shows it at the top for 5 seconds, with Cassy beside the text. Tapping runs the action. The refresh summary and the end-of-queue offer use it. The bookmark toast keeps its note field and gains Cassy cheering.

### D6. Refresh summary

- `Library.triage` returns a `TriageResult` with counts of episodes sent to the Inbox, the Queue, and the archive. `expireInbox` returns its count.
- `FeedService.refreshAll` returns a `RefreshSummary(arrived:queued:skipped:expired:)`.
- `RefreshSummary.sentence` is a pure function: "N new episode(s)." for everything triaged, then "I queued A, skipped B, and removed C old one(s) from your Inbox." with the zero parts left out. It returns nil when nothing moved.
- `AppModel.refresh` shows the toast for refreshes on open and pull to refresh, not for background refreshes, and tapping it opens the Inbox.

### D7. End of the Queue

`Player` gains `queueRanOutAt: Date?`, set when an episode ends with no next Queue item and no end-of-episode sleep timer. `AppModel` watches it with `Observations` and shows the offer. Check Now calls `refresh()`.

### D8. Screens

- **Shows:** a `LazyVGrid` of three columns, each tile an artwork square with the title under it, a star badge for Auto-queue and Play Next, and a warning badge for a failing feed.
- **Show page:** a header with 150-point artwork, the title, and the author, above the existing sections. A failing feed shows Cassy dizzy in the status row.
- **Rows:** `EpisodeRow` gains 52-point artwork on the left.
- **Mini player:** 34-point artwork on the left.
- **Now Playing:** the tint behind everything, and no Cassy: the artwork leads. Offline and audio failures show in Cassy's toast, from any screen, instead of as text under the title.

### D9. Copy

Cassy speaks in the first person. Rows and buttons stay plain.

| Where | Line |
|---|---|
| Empty Queue | **Silence. Lovely, but let's fix that.** Star the shows you never miss and I'll queue their new episodes right here. Button: Find Shows |
| Empty Inbox | **Inbox zero!** Everything's sorted. Go stretch your legs. |
| Failing feed (show page) | This feed is playing hide and seek. I'll look again on the next refresh. Last heard from it 2 days ago. |
| Auto-queue card | Queue new {show} episodes for you? Reason: You play it the day it drops. Button: Queue them. Menu: Never ask about this show |
| Ignored card | Skip new {show} episodes? Reason: Its recent episodes expired unplayed. Button: Skip them. Menu: Unsubscribe, Never ask about this show |
| Refresh summary | 3 new episodes. I queued 1 and removed 2 old ones from your Inbox. |
| End of the Queue | That's the lot. Want me to check for new episodes? Button: Check Now |
| Onboarding intro | Hi, I'm Cassy. Star the shows you never miss and I'll queue their new episodes for you. |
| First star | Nice pick! I'll queue its new episodes. |
| Bookmark toast | Bookmarked at 12:34. Button: Add Note |
| Offline, not downloaded | You're offline, and this one isn't downloaded yet. |
| Audio failed | This episode wouldn't play. Its audio may have moved. |
| Top shows failed | I couldn't load the top shows. Search still works. |
| Empty Bookmarks | Nothing saved yet. Tap the bookmark while you listen and I'll keep the moment. |

### D10. Idle loops and the rule card

- `CassyAnimation` in `CasterrCore` is the catalog of every animation. Eight are idle loops (blink, wink, look around, breathe, reel twitch, hum, yawn, peek), each with a duration; the rest are functional (dozing, cheer, dizzy) and repeat for as long as their job lasts. Only idle loops join the random rotation: `nextIdleLoop(after:using:)` never repeats the last one, the first pause is 2 to 5 seconds, and later ones 8 to 15.
- `CassyJob` maps each job to one functional animation: asleep to dozing, success to cheer, error to dizzy. The idle job plays the random loops. Choosing a different animation for a job changes one line.
- `CassyView(job:)` runs the scheduler for the idle job and draws whichever animation the catalog names. Her timeline only runs while something moves.
- The rule card is the layout picked in the [Cassy Suggestions](https://claude.ai/code/artifact/cc31c16b-ccb1-42ee-8781-a319959aca9c) mockup: Cassy idle, the question with the show name in `Color.tangerineText` (darker in light mode, lighter in dark, for 4.5:1 contrast), the reason, one accept button, "…", a corner ✕, and swipe left to dismiss.
- Sheets and full-screen covers get the tint and rounded type because both are set on the app's root view.

### D11. Her eyes

Her everyday eyes are round pupils with a white highlight in cream sockets (option 2, Shine). The spoked reels read as an X when small, so they only appear where they spin: loading (bounce or jog) and the reel-twitch loop. Her job's animation is picked when she's created, so a short load still shows it from the first frame.

## Risks / Trade-offs

- [Toasts can pile up after a busy refresh] → One Cassy toast at a time; a new one replaces the old.
- [The tint can be muddy for grey artwork] → The saturation lift and brightness cap keep it a readable dark color; grey art gives a dark grey, which is fine.
- [Large title appearance is UIKit] → One appearance call at launch, no other UIKit.

## Migration Plan

No data changes.
