# Design

## Context

`InboxView` is one `List`: an optional Suggestions section, then one section of `EpisodeRow`s with a leading Add to Queue swipe and a trailing Remove swipe, then the expiry footer. The change puts the first episode on a card and the rest under "Also new · N". The mockup is option C in the "Swipe Inbox" page.

## Decisions

**The card stays in the List.** It is the first row of the episodes section, with its background and insets cleared, so the Inbox keeps one scroll, the pull to refresh, the footer, and the tip overlay. A view above the List would need its own scroll handling.

**A horizontal drag, not `swipeActions`.** The card uses a `DragGesture` that only takes over when the movement is mostly sideways, so a vertical drag that starts on the card still scrolls the List. The card has no `swipeActions`. If the drag fights the scroll on the iPhone, the fallback is a `.simultaneousGesture` with a larger minimum distance. This is the main risk; task 2.1 checks it first.

**One point of acting.** A third of the card width, or a fast flick in the same direction. `.sensoryFeedback(.impact(weight: .light))` fires when the drag crosses it.

**Saving.** The card calls the same library methods as the row swipes (`addToQueue`, `dismiss`) through `model.change(.episodes)`. It hides its episode at once from local state, so the next episode takes the card without waiting for the reload.

**The next episode takes the card.** The card's content changes to the next episode with an opacity transition, and the List removes that episode's row with its own delete animation, so the rows slide up. A shared-element move from the row into the card is not worth the risk inside a List.

**Description.** The episode summary without HTML, three lines. `ShowInfo.plainSummary` already strips tags and entities with `HTMLText`; the episode gets the same through one shared helper.

**Accessibility.** The card is one element with the row's label and `accessibilityAction`s Add to Queue and Remove, plus the tap action.

## Risks

- A sideways drag inside a scrolling List can delay or steal the scroll. Checked on the iPhone before the rest.
- The card's fly-off and the List's row removal run in one animation; they must not stutter on the iPhone. Measured with the Animation Hitches recorder if it looks rough.
