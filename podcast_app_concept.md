# Casterr: Product Concept

**Platform:** iOS, native SwiftUI, latest major iOS only
**Model:** Free, open source (MPL-2.0), local-first, no accounts, no server

## The pitch

> **A podcast inbox that triages itself.**
>
> Open the app and something good is ready to play. Casterr sorts new episodes for you, explains every move it makes, and lets you change any of them in one tap.

## Who it's for and how we know it works

Casterr is first the app I use every day. The first people outside that are mainstream listeners coming from Apple Podcasts or Spotify. They rarely triage by hand, so the triage has to happen for them and stay out of the way.

The MVP works when I delete my current podcast app and don't go back. After that, 5 to 10 outside listeners try it on TestFlight.

## Design rules

1. **Sensible defaults.** Every capability works without configuration.
2. **Customize in context.** Change behavior where it matters (on a show, in Now Playing), not in a sprawling settings screen. A small Settings screen holds only the global defaults (Inbox expiry, downloads, default speed), and the places that use them link straight to their section. Per-show speed is set in Now Playing, scoped to "This show" or "All shows".
3. **Explainable automation.** Every automatic move has a visible reason, and the episode's actions are one tap away.
4. **Capture never interrupts listening.** Saving a moment is one tap. Notes are optional.

## Look and feel

Casterr is warm and a little funny. The accent is tangerine orange, titles use heavy rounded type (SF Pro Rounded), and show art appears in every list, on a Shows grid, on the show page, and in the mini player. Now Playing is tinted by the show's artwork. The copy is warm and witty in one voice, with no setting: an empty Queue says "Silence. Lovely, but let's fix that."

The app icon is Cassy, tilted like a sticker, on a tangerine gradient. In dark mode she turns a light orange on a dark ground. It's an Icon Composer file, `Casterr/AppIcon.icon`, so iOS draws the tinted and clear versions from its layers.

The mascot is **Cassy**, a cassette tape whose two reels are her eyes. She is drawn as a sticker: a cream body, a dark outline, and a hard orange shadow, which keeps her visible on orange, dark, and tinted backgrounds. Her reels spin while audio plays, she dozes on an empty Queue, cheers when the Inbox is cleared, and gets dizzy (spiral eyes) when a feed fails. She is never angry. On first launch, one welcome screen has Cassy explain three steps: follow shows, queue the episodes you want from the Inbox, and press play. After that, onboarding teaches with just-in-time tips: a sticker bubble from Cassy that points at a control the first time you need it, shows once, and closes with its ✕ or any tap. The design mockups are in the [Casterr Glow-Up](https://claude.ai/code/artifact/061fffba-976f-4602-964d-47ebcb6d1d04) page.

## How it works

**Home is the Queue.** The top item is always Now Playing. A "New (N)" count links to the Inbox.

**Every show has a triage level.** New episodes follow it:

| Level | New episodes |
|---|---|
| Auto-queue | Go to the bottom of the Queue |
| Play next | Go right after Now Playing, stacked in release order |
| Inbox | Wait in the Inbox, then expire |
| Skip | Never go to your Inbox or Queue; they stay on the show page |

New subscriptions start at Inbox. In onboarding you star the shows you never miss, and those start at Auto-queue. Play next episodes stack above anything you queued yourself.

**Inbox episodes expire.** After 14 days, an untouched episode moves to the show's archive. The choices are 1, 3, 7, 14, or 30 days, or never. You set your default from the Inbox; a show follows it unless you turn off "Use my default" in that show's settings and pick its own value.

**The app suggests rules, you accept them.** Casterr watches what you do with each show: what you play, how soon, and what you let expire. When a pattern shows up, a one-line card appears at the top of the Inbox and counts in the "New (N)" row:

- "You played the last 4 History Show episodes within a day of release. Auto-queue new ones?"
- "Tech Weekly: last 3 expired unplayed. Skip, unsubscribe, or keep?"

These two cards are all of M4. The thresholds are constants, tuned from real use. One tap accepts. "Not now" hides the card for 30 days. "Never for this show" hides it for good. Nothing changes without your tap, except expiry, which is a rule you set. Learning uses behavior only, no language model. There are no filters: cards only change a show's level or unsubscribe. Judging an episode by its length, title, or topic comes later.

**Reasons.** Each episode remembers its latest move: why it happened and when. An automatic move shows its reason on the episode, such as "Auto-queued" or "Removed after 7 days". There is no Undo button: the episode's action line moves it wherever you want.

**Episode rows.** In the Queue, the Inbox, and on show pages, a tap on an episode opens a line of actions under it, with Play first: Play Next, Add to Queue, Played, Share, Show, and Remove, as each screen needs. The swipes stay as shortcuts. Every row shows its status the same way, in gray words above the title (Queued, In Inbox, Played, Downloaded, or minutes left for a started episode), and only what plays next is orange.

## Words

One word per idea, in everything people read in the app:

| Word | Means | Not |
|---|---|---|
| **Remove** | An episode leaves your Inbox or Queue, because you removed it or because it waited too long. It stays on its show page. | dismiss, clear, archive, tidy, delete |
| **Skip** | A show's new episodes never enter your Inbox or Queue. | archive |
| **Dismiss** | Close one of Cassy's cards or tips. Never used for episodes. | remove |
| **Delete** | Bookmarks and shared files only, because they really are deleted. | remove |
| **Follow** | Add a show, so its new episodes come in. Unfollow stops them. As in Apple Podcasts. | subscribe |

"Archive" and "subscribe" are terms inside the code and specs only.

## Player

- Streaming plus downloads. The top 3 Queue episodes download on Wi-Fi, also in the background, and the number is a setting. A file is deleted when its episode leaves that range, for example after you play it.
- Background audio, lock screen and Control Center controls, sleep timer.
- Playback speed from 1x to 2x with natural-sounding pitch. It has a global default, and each show can override it.
- Skip forward is 30 seconds and skip back is 15, the same on every show. They are not configurable for now.
- **Back a Beat:** when you play again after a pause, Casterr resumes at the latest quiet gap between 5 and 2 seconds before where you paused, so you hear the end of the thought. With no gap it resumes where you paused. It works for streamed and downloaded episodes and has no setting.
- **Voice boost:** evens out loud and quiet voices, so a quiet guest is as easy to hear as the host. It is off by default, with a switch in Settings, and each show can override it from a waveform button in Now Playing. Switching applies right away.
- **Chapters:** from the audio file, or else from a timestamp list in the show notes. A pill under the show name in Now Playing shows the current chapter and fills as it plays; tapping it lists every chapter as its own progress bar, with the time left in the playing one, and a tap jumps there. A chapter's own picture replaces the artwork while it plays. The lock screen keeps skipping 30 and 15 seconds.
- An episode counts as played when fewer than 60 seconds remain, or when you mark it played.

## Capture

One tap in Now Playing or on the mini player bookmarks the current episode and timestamp without pausing. A toast confirms it and offers Add Note. Notes are optional and editable later, in place in the Bookmarks tab. The Bookmarks tab searches notes, episode titles, and show titles. Each episode's bookmarks share as one Markdown file through the share sheet, ready for Obsidian, Notes, or any notes app. Export All shares every listed bookmark as one file. A bookmark keeps the show title, episode title, and audio URL, so it survives the episode disappearing from the feed.

## Sharing to Casterr

Casterr appears in other apps' share sheets for audio files (MP3, M4A, and WhatsApp and Telegram voice notes) and Apple Podcasts episode links. A shared item plays next, like Play next, and a small card with Cassy says "Up next in your Queue". A shared file stays on this phone in the built-in show "Shared with Casterr", with Cassy as its art, until you delete it there; it never syncs, and other devices don't show it. An Apple Podcasts link finds the episode through Apple's lookup and queues it without following the show, or reuses the episode you already have; the show's page offers Subscribe.

## Sharing from Casterr

Now Playing has a share button with Share Episode and Share Clip; episode rows have Share in their action line and the show page has Share Show. An episode goes out as "Episode – Show" with its own web page from the feed, or its audio link, and "from 12:34" when shared from Now Playing. A show goes out with its web page or feed address. Share Clip opens a small editor on the two minutes around now, drawn as loudness bars, with a 30-second clip whose edges snap to pauses between words; you drag it to 5 to 60 seconds and can preview it. The clip becomes a square video of the art Now Playing shows, with a "Clipped with Casterr" badge in the top left, at normal speed, sent with the episode's text and link. Streamed MP3s fetch only those two minutes; other streams ask you to download the episode first. Files in Shared with Casterr have no share actions.

## Onboarding and subscribing

- The app has three tabs: Queue, Shows, and Bookmarks. The Inbox stays one tap from the Queue.
- Suggestions come from Apple's documented top podcasts chart for the phone's region, with no genres and no personal picks, under the heading "Popular now" with the region's name. Onboarding shows them with search on first launch, after the welcome screen, and you can skip it. The same view fills the Shows tab whenever you follow nothing. Later, Find Shows in the Shows tab's + menu opens the same screen; the Shows tab's own search covers only the shows you follow. The last top 25 of your region and of the United States, and all show art, are kept on the phone, and Settings can clear them. Outside the United States, the heading switches the chart, and search, to the United States and back. There's no worldwide chart, because Apple has none.
- Search uses the iTunes Search API, which needs no key. It sits behind a provider interface so another directory can be added later.
- You can also import an OPML file or paste an RSS URL, and export your subscriptions as OPML. As far as I know, Apple Podcasts and Spotify don't export OPML, so mainstream switchers rely on search and suggestions.
- Subscribing puts the newest episode through the show's level. Older episodes stay on the show page until you pick them.
- Unsubscribing clears the show's Inbox episodes. Anything you queued stays, and so do bookmarks and history.

## Ownership and privacy

No accounts, ads, tracking, or paywalls. Audio comes straight from publishers' feeds. There is no server, so feeds refresh in the background on a best-effort basis and every time you open the app. iCloud sync through CloudKit comes in M8. When two devices change the same episode, the latest move wins, and that includes the Queue order. Changes from another device show when you open the app or pull to refresh.

## Primitives

Data splits into what comes **from the feed**, a cache that can be wiped and re-fetched, and what is **about you**, which syncs.

| Primitive | What it is | Syncs |
|---|---|---|
| Show | A podcast feed. Identified by its normalized feed URL at subscribe time. That key never changes, even when the feed moves. | No |
| Episode | One feed item. Identified by its GUID, otherwise by its audio URL. | No |
| Subscription | You following a Show: level (including Play next), expiry override, speed override, and the show's recent outcomes for learning | Yes |
| Episode state | Exactly one place (Inbox, Queue, Archive with a reason, or none), its Queue position when queued, listening progress, and its latest move (reason and time) for explanations | Yes |
| Proposal | A pending rule card, computed from outcomes. Only your dismissals are stored. | Dismissals |
| Bookmark | Episode, timestamp, optional note, plus a snapshot of titles and audio URL | Yes |
| Shared with Casterr | The built-in show of files shared to Casterr, and the files themselves | No |
| Settings | Global defaults: expiry, speed, how many Queue episodes to keep downloaded | Yes |
| Download | The audio file on this device | No |

**Invariants**

- An episode is in exactly one place.
- Playing anything moves it to the top of the Queue.
- Automation never reorders what you queued yourself.
- User choices beat automation, and every automatic move says why it happened.

## Roadmap

Each milestone is one OpenSpec change.

1. **Player core:** subscribe by RSS URL or OPML, stream, background audio, lock screen, speed, skip, sleep timer, progress, manual Queue.
2. **Inbox and triage:** levels, expiry, play next, the Inbox screen, and undo of automatic moves.
3. **Downloads and refresh:** auto-download the Queue on Wi-Fi, best-effort background refresh.
4. **Rule cards:** two learned proposals in the Inbox: auto-queue a show you always play, and skip or unsubscribe a show you ignore.
5. **Onboarding:** tabs, top chart suggestions, iTunes search, starring favorites, and OPML export.
6. **Capture:** bookmarks, notes, search, Markdown export.
7. **OPML export:** folded into M5.
8. **CloudKit sync:** the listener sets up the team and container. Done means one phone plus records visible in the CloudKit dashboard.

Then Casterr becomes my daily driver, and TestFlight follows.

**After the MVP:** listening sessions ("I have 25 minutes"), skip silences, topic-aware learning with Apple's on-device model, transcripts, CarPlay, Apple Watch. Parked work is in `BACKLOG.md`.

## Open questions

- The iTunes Search API is limited to about 20 calls a minute, so M5 search needs debouncing.
- The name still needs a trademark check and an App Store name check before launch.

## References

Castro is the main interaction reference for the Inbox and Queue. Pocket Casts, Overcast, and Apple Podcasts set the bar for playback. Check licenses before reusing any open-source code.
