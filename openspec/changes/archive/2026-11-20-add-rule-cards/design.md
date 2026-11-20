# Design

## Context

M2 gave each show a level and each episode a place and its latest move. The concept doc planned "the show's last 10 outcomes" on `Subscription` for learning. With only two cards, both conditions can be read from data that already exists, plus one date. The simplicity rule applies.

## Decisions

### D1. No outcome log

The Ignored card reads the places of the show's newest episodes. The Auto-queue card needs when each episode was first started, which no field holds, because later moves replace the latest move. So `EpisodeState` gains `firstPlayedAt: Date?`, set once when playback first starts. `Player.start` records it, which covers playing, resuming, and moving on to the next Queue item.

- Alternative: a list of recent outcomes on `Subscription`. Rejected, because it duplicates what episode states already say and needs trimming.

### D2. The decision is a pure function

`RuleCard.evaluate(episodes:now:thresholds:) -> RuleCard.Kind?` takes the show's dated episodes, newest first, each with its publish date, `firstPlayedAt`, and place:
- **Ignored** when the newest `ignored` (3) episodes are all `archive(.expired)`.
- **Auto-queue** when the newest `autoQueue` (4) episodes released more than a day before `now` were each started less than a day after release.
- Ignored wins when both hold, because the recent episodes matter more.
- Fewer episodes than a threshold means no card.

`Library.ruleCards()` runs it for each Inbox-level subscription whose card isn't hidden, and returns `[RuleCard]` (show key and kind).

### D3. Hiding

`Subscription` gains `autoQueueCardHiddenUntil: Date?` and `ignoredCardHiddenUntil: Date?`. Not now sets 30 days ahead. Never sets `Date.distantFuture`. A card shows when its date is nil or past.

### D4. Accepting

Accepting calls the existing operations: `setLevel(_:to: .autoQueue)`, `setLevel(_:to: .skip)`, or `FeedService.unsubscribe`. The card disappears because the show is no longer at the Inbox level.

### D5. UI

- The Inbox gets a Suggestions section at the top, with one card per row. Each card shows its sentence and its buttons.
- The "New (N)" count is `inboxCount + ruleCards().count`.
- The thresholds live in `RuleCard.Thresholds` with defaults 4 and 3. `Library.useRuleThresholds` replaces them, so the UI test can raise a card with the fast clock and a threshold of 1.

## Risks / Trade-offs

- [Back-catalog listening never raises the Auto-queue card] → Correct: the card is about new releases.
- [A card can flicker on and off as episodes arrive] → It is recomputed on each load, and it only offers. Nothing changes without a tap.

## Migration Plan

New fields are optional, so lightweight migration adds them. Episodes played before this change have no `firstPlayedAt`, so the Auto-queue card waits for 4 new plays.
