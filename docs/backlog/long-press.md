# Long press actions: findings

Investigated 2026-11-26 by reading the code only. Nothing was built or run, and nothing was checked on a device. The iOS 27 and Human Interface Guidelines points come from memory and are not verified.

## What each screen does today (verified in code)

- **Queue** (`QueueView.swift:37`, `42`, `90`): a tap opens the line of actions, a swipe left removes, and a long press drags to reorder (`.onMove`). The line holds Play, Play Next (not on the top two), Played, Download, Share, Show, Remove.
- **Inbox rows** (`InboxView.swift:108`, `114`, `137`): a tap opens the line, a swipe right adds to the Queue, a swipe left removes. The line holds Play, Play Next, Add to Queue, Share, Show, Remove.
- **Inbox card** (`InboxCard.swift:37`, `70`): a tap opens the line, and a sideways drag queues or removes through `SidewaysPan`. The card has VoiceOver actions (`EpisodeRow.swift:139`). Rule cards have a "..." menu (Unfollow, Never ask) and a swipe to dismiss (`InboxView.swift`, around 180 to 210).
- **Shows** (`ShowsView.swift:71-79`, `157`): a grid of tiles that open the show. No line, no swipe, no menu. The only menu is Add in the toolbar (`46-56`).
- **Show page** (`ShowView.swift:289`, `297`, `315`): swipes and a line on rows. Share Show is at `116`. Unfollow asks for confirmation (`149`).
- **Bookmarks** (`BookmarksView.swift:216`): a swipe to delete, nothing else.
- No `contextMenu`, `onLongPressGesture` or preview exists in Casterr yet.

## What iOS offers

A context menu (`contextMenu(menuItems:preview:)`) fits rows and tiles. `contextMenu(forSelectionType:)` belongs to List selection, which these screens don't use. The guidelines, from memory: a menu holds secondary actions, destructive items go last, a preview is for content that needs a closer look, and a menu must not be the only way to reach an action.

## Risks

- **Queue:** a long press already starts reordering (`openspec/specs/queue/spec.md:47`). A menu on the same press competes with it. Inferred; needs a device test.
- **Row buttons:** a menu on a Button in a List usually works. Whether letting go also fires the tap is inferred.
- **Inbox card:** `SidewaysPan` starts only on sideways movement, so a still press should reach the menu. Inferred.
- **VoiceOver:** the line of actions already reaches every action. Whether menu items also appear as VoiceOver actions is inferred.
- **Words:** reuse Remove, Delete, Played and Play Next. Don't use "Dismiss" for episodes.
- **Share:** `ArtShareLink` is a custom view, and whether it works inside a menu needs a check.

## Recommendation

The simplest design reuses what exists:

- One `.contextMenu` on the episode row's header, listing Play and then the row's existing actions. No second list of actions and no custom preview (the row itself is the preview).
- Use it on Inbox rows, the Inbox card and show page rows.
- **Shows tiles** get a menu with Star, Share Show and Unfollow, reusing the show page's confirmation (`ShowView.swift:149`). This is the only screen where long press adds actions that aren't reachable from the screen today.
- **Queue:** leave it out at first. The line already has the actions, and long press means reorder there. Try it on a device before adding it.

## Alternatives

- **A. Long press opens the line of actions** (`onLongPressGesture { toggle() }`). The least code and no system menu. It still clashes with reordering in the Queue, and gives Shows tiles nothing.
- **B. A menu on the Queue too**, tested on a device. Covers every screen, but may break reordering. Drop it there if dragging fails.

## Not checked

The iOS 27 API signatures, the guidelines' exact wording, and any behavior on a device.
