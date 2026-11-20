# Proposal

## Why

After the Tangerine redesign, a screen-by-screen walkthrough found places where the app was confusing, inconsistent, or hid how it works: an unlabeled clock menu, settings named "Send to" and "Remove after", a "Now Playing" label on an episode that wasn't playing, six different words for removing an episode, and a swipe that could send you back instead of queuing. This change records the decisions from that walkthrough, each picked from labeled mockups.

## What Changes

- **Find Shows:** one Cassy at a time, a loading state, a couldn't-load state with Try Again, a card above the list that turns into a cheer after the first star, and a large title. Directory requests time out after 10 seconds and the chart is retried once.
- **Just-in-time tips:** a reusable sticker tip that points at a control, shows once, and closes with its ✕ or any tap. The first follow with + teaches the star; the first Inbox visit teaches the swipes.
- **Shows tab:** grey background, and search that lists your matching shows before the directory's.
- **Show page:** no title in the bar, a two-line description, new-episode settings as one summary row that opens a sheet with a "Use my default" toggle and six presets, and played episodes folded into one row above the list.
- **Queue:** the first episode says Playing, Paused, or Up next; an empty Queue points at a waiting Inbox; no Edit button; a bar offers the next Queue episode while nothing plays.
- **Inbox:** "Inbox · N new" on the Queue, a line that says how long episodes wait and opens Settings, a quiet countdown in an episode's last 3 days.
- **Settings:** a small screen with only the global defaults.
- **Expiry default:** 14 days instead of 7, with 1 day added to the choices.
- **Words:** one word per idea in the app (Remove, Skip, Dismiss, Delete); "archive" never appears.

## Capabilities

### New Capabilities

- `show-page`: the show page's header, new-episode settings, and played episodes.
- `settings`: the global defaults screen.

### Modified Capabilities

- `discovery`: top shows failures and onboarding; adds just-in-time tips.
- `subscriptions`: adds searching your shows.
- `triage`: the Inbox, Inbox expiry, and the automatic-move labels.
- `queue`: the home screen, managing the Queue, and adds the up-next bar.
- `look-and-feel`: adds one word per idea.

## Out of scope

- Typo-tolerant search.
- An exact number for expiry.
- Now Playing and Bookmarks, which come in the next walkthrough steps.

## Impact

- `CasterrCore`: `ShowSearch`, `ShowInfo.plainSummary`, `Library.inboxDaysLeft()`, the 14-day default and presets, the directory timeout and retry, and new label and summary wording.
- App: `CassyTip`, `SettingsView`, `NewEpisodesSheet`, `RowSwipes`, and changes across Find Shows, Shows, the show page, the Queue, and the Inbox.
- **Order:** archive after `add-cassy-look`.
