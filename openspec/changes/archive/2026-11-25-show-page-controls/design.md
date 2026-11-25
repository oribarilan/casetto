# Design

## Context

`ShowView` draws Follow and Star with `ShowPageButton`, a full-width `.borderedProminent` capsule. When a button is on, it's tinted pale tangerine. Since 0.4.1 a tap shows its result at once from `pendingFollow` and `pendingStar`. Saves then run one after another through `act`, and the saved state takes over when the last one lands.

The New episodes row only shows when `subscription`, the saved follow, exists. Following calls `FeedService.subscribe`, which fetches and parses the feed before it saves, so `subscription` arrives seconds after the tap. `loadFollow()` also sets it without animation, so the row pops in late. The row opens `NewEpisodesSheet`: four tiles, a "Use my default" toggle, and a segmented control for the Inbox period. Nothing else opens the sheet.

`Library.setStarred` moves an Inbox show to Queue when it stars it. `subscribe(to:level:)` follows at Inbox unless told otherwise, and Star follows at Queue.

## Goals / Non-Goals

**Goals:** a quieter pair of buttons, a row that says what it is, and a row that appears and changes without a jump.

**Non-Goals:** Find Shows' buttons, haptics, and making `subscribe` itself faster.

## Decisions

**Follow stays a capsule; only its tint changes.** `ShowPageButton` keeps one button for both looks, so the spin still runs. When on, it's tinted a grey system fill with the primary text color. When off, it's tangerine with `onTangerine` text, as today. It no longer takes the full width: Follow fills the space Star leaves.

**Star becomes a round `.bordered` button with `.buttonBorderShape(.circle)`.** It's grey with a `star` or a tangerine `star.fill`, at the same height as Follow, and it keeps the `-144` degree spin. Its accessibility label stays "Star" or "Starred", so VoiceOver and the UI tests read the same words as today. Alternative: a plain icon with no circle. That was option D, and the listener didn't pick it.

**Each row is a `Menu` around an inline `Picker`.** The row's label is our own: the name on the left, then the value and an up-down chevron on the right, so the value can cross-fade and "Removed after" can read "14 days" while its menu item reads "My default (14 days)". A plain menu `Picker` would show the selected item's own text in the row. Inside the menu, the `Picker` draws the check on the current choice. Each level is a `Button` with two `Text`s, which iOS 27 shows as a title and a subtitle (checked on the simulator). The Removed after menu lists `nil` (My default) first and then `InboxExpiry.choices`. Its value reads the period whether it's the default or the show's own. The menu's check shows which one it is, as in the mockup. Alternative: keep the sheet and only rename the row (option 1). The listener picked the menu.

**The sheet is deleted.** The two pickers do everything it did, and the toggle goes away because My default is a menu choice. The longer sentences it showed ("If you don't play a new episode within 14 days, ...") go with it. The row's own words now carry that meaning.

**The row reads the pending follow, not only the saved one.** A new `pendingLevel` and `pendingOverride` join `pendingFollow` and `pendingStar`, and `act` sets and clears all four together. The row shows when `pendingFollow ?? (subscription != nil)` is true, with the level `pendingLevel ?? subscription?.level`. Follow sets `pendingLevel` to Inbox. Star sets it to Queue when the show isn't followed or is at Inbox, which is what `setStarred` will save. The tap reads the new values before it calls `act`, because the save runs after the pending values have changed what the page shows. A menu choice goes through `act` too, so it runs after a follow that is still saving, and the row keeps showing it. If the follow fails, the reload finds no subscription, the pending values clear, and the row shrinks away.

**List animations do the growing.** The pending values change inside `withAnimation(.snappy)`, so the List inserts and removes the rows with its own animation, and the episode rows slide with it. `act` makes that change as the first step of its save task, not in the button action: on the iOS 27 simulator, a change made inside the tapped List row inserted the rows in one frame, even with a 3-second animation, while the same change a moment later animated. The task also makes sure the values show before the save runs. The picker's value gets `.contentTransition(.opacity)`, so a new choice cross-fades. With Reduce Motion on, `act` changes the values with no animation.

**Version 0.6.** This changes what the listener sees, so it's a minor bump from 0.5.1, with a new `CHANGELOG.md` section.

## Risks / Trade-offs

- [The Removed after value doesn't say whether it's the default] → The menu's check says it, and the mockup the listener approved shows only the period. Easy to add "(default)" later if they want it.
- [A menu choice during a pending follow saves after `subscribe`, which can take seconds] → The row shows the choice the whole time, so the wait isn't visible.
- [Following no longer looks tappable once it's grey] → It's still a capsule, the same shape as Follow, and tapping it asks to unfollow as today.
