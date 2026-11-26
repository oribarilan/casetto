# Design

## Context

`RootView` builds a `TabView` bound to `model.tab`, with one `NavigationStack` for each tab, each bound to a path in `AppModel` (`queuePath`, `showsPath`, `bookmarksPath`). The app sets `model.tab` and a path by itself in four places: the refresh message (Queue with the Inbox), the bookmark message (Bookmarks), the up-next bar (Queue), and a show tapped in Now Playing (Shows with the show).

## Decisions

- **Reset in the tab selection's setter, not in `onChange(of: model.tab)`.** The `TabView` gets a `Binding` whose setter runs only on the listener's tab taps. On a tap on Queue, or on a tap on the open tab, it empties that tab's path, then sets `model.tab`. Code that sets `model.tab` directly, such as the refresh message, does not pass through the setter, so its path stays. `onChange` would also fire for those and would undo the refresh message's `[.inbox]`.
- **The second tap is already done by iOS.** Checked in the simulator (task 1.1): with Settings open in the Queue tab, a tap on the Queue tab goes back to the Queue with today's code. So the setter handles only the Queue rule: on a tap on Queue, it empties `queuePath`. `testTabTaps` checks the second tap on Shows too.

## Risks / Trade-offs

- The refresh message's link from another tab is checked on the iPhone, not in a UI test. The message lasts 5 seconds, and XCUITest waits for the app to settle before each tap, so the tap came too late to hit it, with the old code as well.

- The Inbox's scroll position is lost when the listener comes back to the Queue. The Inbox is one tap away and every swipe is already saved, so the listener agreed to this.
