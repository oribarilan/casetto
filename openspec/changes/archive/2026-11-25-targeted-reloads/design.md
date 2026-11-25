## Context

See proposal.md, Why, for the measurements. `AppModel.revision` is one `Int`. Seven screens reload with `.task(id: model.revision)`, and CarPlay watches it too. `change(_:)` bumps it after every save; so do a feed refresh, a new bookmark, a finished download, and a download sync that deleted files. `revision` also re-runs `loadUpNext()`, and every `change` runs `syncDownloads()`.

## Goals / Non-Goals

**Goals:** a change redoes only the reads that depend on what it touched; coming back to a screen costs nothing when nothing changed; the rule is simple enough to follow in every new screen.

**Non-Goals:** fine-grained per-show or per-episode counters; live queries in views.

## Decisions

**Per-area counters, observed by SwiftUI.** `AppModel` holds a small value, `DataRevisions`, with one counter per area: `follows`, `episodes`, `feeds`, `bookmarks`, `settings`, `downloads`. A screen's reload task uses as its id only the counters it reads, so SwiftUI re-runs only the tasks whose counters moved.

Alternatives:
- An enum of what changed, which every screen inspects: each screen would carry its own matching code, and the matching would drift from what it reads.
- Keep one counter, and have screens compare the new data with the old: they would still re-read 1,382 episodes to find out nothing changed.
- Per-show counters: finer, but the per-area split already removes the big reads; add it only if the measurements say so.

**`change(_ areas:, work)` with an option set.** `DataArea` is an option set; `.all` is the default, so an unsure call site keeps today's behavior. Each call site names its areas: Star and Follow touch `follows` (Follow also `feeds` and `episodes`, since it saves the feed and fills the Inbox); queue and Inbox actions touch `episodes`; Settings touch `settings`; bookmarks touch `bookmarks`; a refresh touches `feeds` and `episodes`.

**The show page splits its reload in two.** Its follow part reads the subscription, the cached feed address, and the default expiry, on `follows` and `settings`. Its episode part reads the show, the episodes, their places, and the top of the Queue, on `feeds` and `episodes`. A Star runs only the first, a few reads instead of thousands.

**Reload on return only when stale.** A small modifier, `.reload(on: id) { … }`, remembers the id it last loaded for and skips the reload when a screen comes back with the same id. It replaces `.task(id: model.revision)` on every screen.

**Downloads redraw without re-reading.** A finished download bumps only `downloads`. Rows already compute their download words from the app model; the screens that show them read `downloads` in their body, so the words update with no library read.

**Check the Queue against only its own keys.** `playableQueue` and the Play next position need to know which queued episodes this device has. They loaded every episode record in the library to find out, twice per change that touches episodes. They now fetch only the records whose keys are in the Queue, which is a handful of rows.

**The library runs off the main thread.** `Library` is a SwiftData model actor. SwiftData's default executor runs each job on the thread that asks for it, so every read and save from the app model ran on the main thread and competed with animations. The phone profile showed it: all of Unfollow's 217 ms of library work ran on the main thread. A test showed that making the actor on a background thread doesn't help. The library now has its own executor, `LibraryExecutor`, which runs its jobs one at a time on a private serial queue. A core test opens a library on the main actor and checks that its work runs off the main thread.

Alternatives:
- Keep the library on the main thread and make every read cheap: each new screen or bigger library brings the stalls back.
- A second, background library only for heavy reads: two contexts on one store must agree after each save, which is more code and a new kind of bug.

**The 0.6 s wait goes.** It hid main-thread work. With the library off the main thread and the targeted reloads in, the listener saw a smooth spin without it, so it and its `afterSpin` plumbing are removed. The queued saves stay: they stop taps from being dropped.

## Risks / Trade-offs

- [Library calls now take a real hop to another queue, so code that assumed they finish within a few yields breaks] → The player tests' `settle()` waits on library round trips instead of yields; the full UI suite covers the app's timing.

- [A call site names too few areas, so a screen shows stale data] → `.all` is the default; narrow only call sites whose effects are clear from the library method. The full UI suite covers each screen's reload after its actions.
- [Two places to keep in sync: the areas a change names and the areas a screen reads] → The AGENTS.md rule, and area names that match the library's sections.
