# Tasks

## 1. Screens

- [x] 1.1 Rework Find Shows (one Cassy, loading and failure states, the intro card and cheer, a large title), and verify in the onboarding UI test
- [x] 1.2 Build the `CassyTip` component, use it for the first-follow star tip, add the AGENTS.md rule, and verify in a star tip UI test that the tip shows once and its ✕ closes it
- [x] 1.3 Time directory requests out after 10 seconds and retry the chart once, with a test, and make the UI tests tap Try Again during a chart outage
- [x] 1.4 Shows tab: grey background, "Search shows", and the split search with `ShowSearch` and its tests
- [x] 1.5 Show page: no bar title, the description with More, the new-episodes summary row and sheet with the "Use my default" toggle and the six presets, a 14-day global default, and played episodes folded above the list; verify in the screens and Inbox UI tests
- [x] 1.6 Queue: the playing, paused, or up-next label, the empty state that points at the Inbox, no Edit button, the up-next bar, per-tab navigation paths, and `keepsRowSwipes()`; verify reordering by drag, the bar, and playing from it in the screens UI test
- [x] 1.7 Inbox and Settings: the Settings screen and gear, the Inbox expiry line, the last-3-days countdown with `inboxDaysLeft` and its test, the one-time swipe tip, and "Inbox · 1 new"; verify in the Inbox, screens, and new Inbox tip UI tests
- [x] 1.8 Align every user-facing word with the glossary (Remove, Skip, Dismiss, Delete; no "archive" in the app), the Queue swipe says Remove, and add the glossary to the concept doc and AGENTS.md; verify all UI tests and `swift test` pass

## Workflow follow-up

- Archive after `add-cassy-look`.
