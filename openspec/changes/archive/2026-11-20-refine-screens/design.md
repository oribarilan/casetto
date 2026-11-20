# Design

## Context

After the Tangerine redesign (`add-cassy-look`), the listener walked through every screen and decided changes one at a time from labeled mockups. This change records those decisions. Requirements are in this change's specs; the simplicity rule applies.

## Decisions

### D1. Find Shows and just-in-time tips

- Find Shows shows one Cassy at a time: big and loading ("Flipping through the shelves…") while the list loads, dizzy with Try Again if it fails, and otherwise in a card above the list ("These are popular right now. Tap + to follow any of them…"), which turns into the "Nice pick!" cheer after a star. The old intro banner is gone, and the title is large like every other screen.
- `CassyTip` (`Casterr/Screens/CassyTip.swift`) is a reusable one-time tip: a sticker bubble with a tail that points at a `cassyTipTarget`, a subtle grey ✕, and closing on any other tap. `CassyTip.once(_:target:text:)` remembers each tip per install. The first follow with + shows the star tip; starring first marks it as shown. AGENTS.md tells agents to use it for onboarding instead of banners or tutorials.
- Apple's chart endpoint fails now and then (a 502, or a 20-second timeout, about one request in three on the day this was built). Directory requests time out after 10 seconds, and the chart is retried once.

### D2. Shows tab and show page

- The Shows tab has the grey grouped background. Its search, "Search shows", lists your matching shows first ("Your shows", matched on the device by `ShowSearch`: every word must appear in the title or author, ignoring case and accents, no typo tolerance), then "More shows" from the directory without the ones you follow.
- The show page drops the title from the bar; the header names the show and shows two lines of its description (`ShowInfo.plainSummary`, without HTML) with More.
- New-episode settings become one summary row ("New episodes: go to your Inbox, removed after 14 days (your default)"). It opens `NewEpisodesSheet`, a half sheet with four tiles (`tray`, `text.badge.plus`, `text.line.first.and.arrowtriangle.forward`, `archivebox`). For Inbox shows, a "Use my default" toggle follows the global period; turning it off gives the show its own value, starting at the current default, picked from 1d, 3d, 7d, 14d, 30d, or Never. The global default is now 14 days.
- Played episodes fold into a "Played (N)" row above the episode list. It sits above, not below, because big shows list hundreds of back-catalog episodes, which would bury a row at the end.
- No emoji anywhere in the app; icons are SF Symbols. AGENTS.md says so.

### D3. Queue

- The first episode says what it is: "Playing" with the animated `waveform` symbol, "Paused" when it's loaded but stopped, or "Up next".
- An empty Queue with something waiting in the Inbox says so ("Your Queue is empty, but 1 new episode is waiting.") with Open Inbox, instead of suggesting new shows.
- No Edit button: long-press and drag reorders, and swipe removes.
- While nothing plays, the bottom bar offers the first Queue episode: "Up next · from your Queue" for a new one, "Continue · 25 min left" for a started one, with a play button. Tapping the bar opens the Queue.
- Each tab keeps its navigation path in `AppModel`.
- iOS 26 and later also pop a pushed screen on a right swipe anywhere in its content, which beat the rows' "Add to Queue" swipe on the show page and the Inbox. `keepsRowSwipes()` turns off only that content swipe (`interactiveContentPopGestureRecognizer`) on those two screens; the edge swipe still goes back.

### D4. Inbox and Settings

- A small Settings screen holds the global defaults only: Inbox expiry (1d to Never), Keep downloaded (Off to 10), and default speed. It replaces the Queue's Downloads menu with one gear, and opens at a section, briefly highlighted, when a link asks for one (`Route.settings(SettingsSection?)`).
- The Inbox drops its clock menu. A line under the list says "Unplayed episodes are removed after 14 days ›", and the days open Settings at the Inbox section.
- Inbox rows stay quiet until an episode's last 3 days, then end their details line with "removed in 2 days", "removed tomorrow", or "removed soon" (`Library.inboxDaysLeft()`, on the library's clock).
- The first Inbox visit shows a one-time `CassyTip` on the first row: "Swipe right to queue an episode, or left to remove it."
- The Queue's row reads "Inbox · 1 new", matching the screen it opens.

### D5. Words

The app uses one word per idea, from the glossary in `podcast_app_concept.md`: **Remove** when an episode leaves your Inbox or Queue (by you or automatically; it stays on its show page), **Skip** for a show whose new episodes never enter them, **Dismiss** only for Cassy's cards and tips, and **Delete** only for bookmarks. "Archive" is an internal term and never appears in the app. The Queue's swipe now says Remove, not the system's Delete.

## Risks / Trade-offs

- [Apple's chart endpoint fails often (a 502 or a 20-second timeout)] → A 10-second timeout, one retry, and Try Again.
- [Blocking the content back swipe on two screens] → The edge swipe still goes back, which is the standard gesture.
- [No exact expiry number] → Six presets cover the useful range; a missing one is easy to add.
