# Tasks

## 1. Core

- [x] 1.1 Add `RuleCard` with `evaluate` and `Thresholds`, and verify unit tests for each card, a late play, too few episodes, recent releases ignored, and Ignored winning over Auto-queue
- [x] 1.2 Add `EpisodeState.firstPlayedAt`, set once by `Player.start`, and verify the CloudKit schema-rules test and a `PlayerTests` case for playing, moving on, and replaying
- [x] 1.3 Add the hide dates, `Library.ruleCards()`, `hideRuleCard`, and `useRuleThresholds`, and verify tests for each card scenario, Not now, Never, and other levels showing no card

## 2. App

- [x] 2.1 Add the Suggestions section to the Inbox with accept, Not now, and Never, count cards in "New (N)", and verify in a UI test with the fast clock and a threshold of 1 that the Ignored card appears and Skip sets the level
- [x] 2.2 Verify that all UI tests and `swift test` pass

## Workflow follow-up

- Archive `add-inbox-triage` before archiving this change.
