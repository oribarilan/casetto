## Context

The Queue, the Inbox and the show page all build their rows from `EpisodeRow`. Today the row is one `Button` whose tap plays the episode, followed by an optional Undo button. Each screen adds its own `swipeActions`. The Queue adds `onMove`, and the show page adds a `contextMenu`. Captions are orange (`.tint`). The Queue passes `downloaded`, which shows an icon in the details line; the other screens don't. `Library` already has every action: `playNext`, `addToQueue`, `removeFromQueue`, `dismiss`, `markPlayed`, `markUnplayed` and `progress(of:)`.

## Goals / Non-Goals

**Goals:**
- One row component that draws the action line and the status line, so the three screens can't drift apart.
- Each screen decides only which actions and which status words apply.

**Non-Goals:**
- No CasterrCore changes beyond `playNextByListener`.
- No change to swipes, drag to reorder, the Inbox swipe tip, Undo, or the Inbox countdown ("removed in 2 days" stays orange at the end of the details line, because it's a warning, not a status).

## Decisions

**The line lives inside the row, not as its own list row.** `EpisodeRow` becomes a `VStack`: the tappable row, then the line when it's open. Swipes and drag then still act on the whole row. A separate list row would need its own swipe and move rules, and dragging could split the two.

**The screen owns which row is open.** Each screen keeps `@State var openRow: EpisodeKey?` and passes `isOpen` and a toggle to the row. That's the simplest way to keep one line open at a time. The line opens and closes with the default animation. Using an action sets `openRow = nil`. Starting a drag doesn't need special code, because the line moves with its row.

**Actions are passed in as a list.** The row takes `[RowAction]`, where `RowAction` holds a title, an SF Symbol, an optional role and a closure. Share is the exception, because it needs `ArtShareLink`, so the row takes an optional share payload and draws it in the same round style. The alternative, a `@ViewBuilder` slot, would let each screen style its own buttons, which is the drift this change removes. Play is first, and its label and symbol come from whether the player is playing this episode (Pause, `pause.fill`).

Symbols: Play `play.fill`, Pause `pause.fill`, Play Next `text.line.first.and.arrowtriangle.forward`, Add to Queue `text.badge.plus`, Played `checkmark.circle`, Unplayed `circle`, Share `square.and.arrow.up`, Show `square.stack`, Remove `minus.circle` (red), Delete `trash` (red). Play is filled tangerine with dark brown, like `filledButton()`. The others are tangerine glyphs on a light gray circle, with labels under them in `.caption2`.

**Status words come from the screen, color from the row.** The row takes `label: String?` (orange: Up next, Playing, Paused) and `statuses: [String]` (gray). The row appends the automatic move reason and "Downloaded" itself, because both are the same on every screen. Each screen leaves out its own place word: the Queue never passes "Queued", the Inbox never passes "In Inbox", and the show page passes the place word from `caption(_:)` as it does today. Gray is `.secondary`. "Downloaded" replaces the icon. A played episode's title uses `.secondary`.

**Minutes left are loaded with the other row data.** Each screen already loads `moves` in one pass. It loads `progress` the same way into `[EpisodeKey: TimeInterval]` and passes it to the row. The row shows `ceil((duration − progress) / 60)` as "N min left" when progress is above 0 and the episode isn't played. The mini player bar already words it the same way.

**Show and Share from the Queue and Inbox.** Show pushes `Route.show(showKey)` on the screen's navigation stack. Share needs the show's title and art. The Queue and Inbox already hold `ShowArt` for each show, so they build the share text from it, and the image comes from `ArtCache`.

**The listener's Play Next is their own move.** `Library.playNext` records the move as automatic, which would show "Play next" and Undo on the row. A small `playNextByListener` puts the episode in the same spot and records it as the listener's move, so it gets no label and no Undo. This is the one CasterrCore addition.

**Share stays open.** Using an action closes the line, except Share: closing it would remove the share link while its sheet opens.

**The show page's `contextMenu` is removed.** Share Episode and Delete move into the line, so the long press would only repeat them.

**Accessibility.** The row button gets the hint "Shows actions". Its label includes the status words. Each action is a real `Button` with its title, so VoiceOver reaches it when the line is open. The swipe actions stay available to VoiceOver as they are today.

## Risks / Trade-offs

- [Playing takes two taps from a row] → The listener chose this. The mini player still plays the first Queue episode in one tap.
- [UI tests tap rows to play] → They tap the row, then Play in the line. One helper keeps that short.
- [The line can push rows below the fold on a small phone] → It's one short line, about 64 pt. The list scrolls.
- [The Inbox has seven candidate actions] → Played is left out of the Inbox to keep six. If the listener wants it back, Show is the next candidate to drop.
