# Casetto: Product Concept

**Platform:** iOS, native SwiftUI, latest major iOS only
**Model:** Free, open source (MPL-2.0), local-first, no accounts, no server

## The pitch

> **A podcast inbox that triages itself.**
>
> Open the app and something good is ready to play. Casetto sorts new episodes for you, explains every move it makes, and lets you undo any of them.

## Who it's for and how we know it works

Casetto is first the app I use every day. The first people outside that are mainstream listeners coming from Apple Podcasts or Spotify. They rarely triage by hand, so the triage has to happen for them and stay out of the way.

The MVP works when I delete my current podcast app and don't go back. After that, 5 to 10 outside listeners try it on TestFlight.

## Design rules

1. **Sensible defaults.** Every capability works without configuration.
2. **Customize in context.** Change behavior where it matters (on a show, in Now Playing), not in a sprawling settings screen.
3. **Explainable, reversible automation.** Every automatic move has a visible reason and an undo.
4. **Capture never interrupts listening.** Saving a moment is one tap. Notes are optional.

## How it works

**Home is the Queue.** The top item is always Now Playing. A "New (N)" count links to the Inbox.

**Every show has a triage level.** New episodes follow it:

| Level | New episodes |
|---|---|
| Auto-queue | Go to the bottom of the Queue |
| Inbox | Wait in the Inbox, then expire |
| Skip | Go straight to the archive |

New subscriptions start at Inbox. In onboarding you star the shows you never miss, and those start at Auto-queue. A show can also be set to "play next". Its new episodes then go to the top of the Queue, stacked in release order above anything you queued yourself.

**Inbox episodes expire.** After 7 days, an untouched episode moves to the show's archive. You can change the 7 days globally or per show, and you can undo it.

**The app suggests rules, you accept them.** Casetto watches what you do with each show. It looks at what you play, finish, dismiss, or let expire, how soon you play things, how long episodes run, and what their titles say. When a pattern shows up, a one-line card appears in the Inbox:

- "You played the last 4 History Show episodes within a day. Auto-queue new ones?"
- "Tech Weekly: last 3 expired unplayed. Skip, unsubscribe, or keep?"
- "You dismiss every episode of this show over 90 minutes. Skip those?"

One tap accepts. "Not now" hides the card for 30 days. "Never for this show" hides it for good. Nothing changes without your tap, except expiry, which is a rule you set. Learning uses behavior only, no language model. Judging an episode by its topic ("I skip this show's sports episodes") comes later.

**Filters are deliberately small.** A show can skip episodes longer than N minutes, or episodes whose title contains certain words. There is no general rule builder.

**Undo.** Every move is logged with its reason for 30 days. An automatic move shows "Undo" on the episode until it moves again. Your own moves get an immediate undo toast.

## Player

- Streaming plus downloads. Queued episodes download on Wi-Fi and are deleted after you play them.
- Background audio, lock screen and Control Center controls, sleep timer.
- Playback speed from 1x to 2x with natural-sounding pitch. It has a global default, and each show can override it.
- Skip forward is 30 seconds and skip back is 15, the same on every show. They are not configurable for now.
- An episode counts as played when fewer than 60 seconds remain, or when you mark it played.

## Capture

One tap bookmarks the current episode and timestamp without pausing. A note is optional. Bookmarks are searchable and export as Markdown, one file per episode, ready for Obsidian, Notes, or any notes app. A bookmark keeps the show title, episode title, and audio URL, so it survives the episode disappearing from the feed.

## Onboarding and subscribing

- Suggestions come from Apple's top charts, by genre.
- Search uses the iTunes Search API, which needs no key. It sits behind a provider interface so another directory can be added later.
- You can also import an OPML file or paste an RSS URL. As far as I know, Apple Podcasts and Spotify don't export OPML, so mainstream switchers rely on search and suggestions.
- Subscribing puts the newest episode through the show's level. Older episodes stay on the show page until you pick them.
- Unsubscribing clears the show's Inbox episodes. Anything you queued stays, and so do bookmarks and history.

## Ownership and privacy

No accounts, ads, tracking, or paywalls. Audio comes straight from publishers' feeds. There is no server, so feeds refresh in the background on a best-effort basis and every time you open the app. iCloud sync through CloudKit comes in M8.

## Primitives

Data splits into what comes **from the feed**, a cache that can be wiped and re-fetched, and what is **about you**, which syncs.

| Primitive | What it is | Syncs |
|---|---|---|
| Show | A podcast feed. Identified by its normalized feed URL at subscribe time. That key never changes, even when the feed moves. | No |
| Episode | One feed item. Identified by its GUID, otherwise by its audio URL. | No |
| Subscription | You following a Show: level, expiry override, play next, filters, speed override, and the show's last 10 outcomes for learning | Yes |
| Episode state | Exactly one place (Inbox, Queue, Archive with a reason, or none) plus listening progress | Yes |
| Queue entry | An episode's position in the Queue | Yes |
| Event | A move with its reason and who made it (you, a level, a filter, expiry). Kept 30 days. | Yes |
| Proposal | A pending rule card, computed from outcomes. Only your dismissals are stored. | Dismissals |
| Bookmark | Episode, timestamp, optional note, plus a snapshot of titles and audio URL | Yes |
| Settings | Global defaults: expiry, speed, download behavior | Yes |
| Download | The audio file on this device | No |

**Invariants**

- An episode is in exactly one place.
- Playing anything moves it to the top of the Queue.
- Automation never reorders what you queued yourself.
- User choices beat automation, and every automatic move can be undone for 30 days.

## Roadmap

Each milestone is one OpenSpec change.

1. **Player core:** subscribe by RSS URL or OPML, stream, background audio, lock screen, speed, skip, sleep timer, progress, manual Queue.
2. **Inbox and triage:** levels, expiry, play next, filters, the event log, and undo.
3. **Downloads and refresh:** auto-download the Queue on Wi-Fi, best-effort background refresh.
4. **Rule cards:** learned proposals in the Inbox.
5. **Onboarding:** Apple charts by genre, iTunes search, starring favorites.
6. **Capture:** bookmarks, notes, search, Markdown export.
7. **OPML export.**
8. **CloudKit sync.**

Then Casetto becomes my daily driver, and TestFlight follows.

**After the MVP:** listening sessions ("I have 25 minutes"), skip silences, voice boost, topic-aware learning with Apple's on-device model, chapters and transcripts, CarPlay, Apple Watch.

## Open questions

- Where do you set a per-show player override: in Now Playing, on the show page, or both? We'll compare mockups during M1.
- The exact thresholds for each rule card get decided in M4.
- Genre charts for onboarding (M5): Apple's documented charts feed has no genre filter. The older iTunes charts URL that does filter by genre still works, but it's undocumented and could break. The iTunes Search API is limited to about 20 calls a minute, so search needs debouncing and caching.
- The name still needs a trademark check and an App Store name check before launch.

## References

Castro is the main interaction reference for the Inbox and Queue. Pocket Casts, Overcast, and Apple Podcasts set the bar for playback. Check licenses before reusing any open-source code.
