# Proposal

## Why

The walkthrough of Now Playing found three problems. The speed sheet's "All shows" option set the same default as Settings, so one setting lived in two places. "Sleep timer on" didn't say how long was left. The show name was a dead end. Each decision was picked from labeled mockups (A2, B2, C1, and D).

## What Changes

- **Speed (A2):** the speed sheet sets only this show's speed. A "Use my default" switch follows the default speed from Settings; turning it off shows a slider for this show. Changes apply as you drag, with no Done button.
- **Sleep timer (B2):** speed, bookmark, and sleep timer are three matching round buttons. While a timer runs, the moon button shows the time left, or "End" for the end of the episode.
- **Scrubber (C1):** keep the system slider.
- **Show name (D):** tapping the show name closes Now Playing and opens the show page.

## Capabilities

### Modified Capabilities

- `playback`: speed default and per-show override, sleep timer, and adds the show name link.

## Out of scope

- A custom scrubber.
- Bookmarks, the next walkthrough step.

## Impact

- `CasterrCore`: `Library.speedOverride(_:)` and `Player.sleepTimerEndsAt`.
- App: `NowPlayingView` and its speed sheet, and `RootView` for the show link.
