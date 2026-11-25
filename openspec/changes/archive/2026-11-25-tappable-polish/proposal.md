# Proposal

## Why

Three things in the app are tappable but don't look it, or look tappable when they aren't. The listener logged them in the backlog on 2026-11-24:

- On a show page, "More" shows even when the description fits in two lines, and its tap area is one small word.
- On Find Shows, the country in "Popular now · Israel" opens a menu, but only the small chevron is in the accent color.
- In Settings, the "What's New" row doesn't look tappable.

This is a backlog fix, not a numbered roadmap milestone.

## What Changes

- **Show page description:** the words become "Show more" and "Show less". They show only when the description is cut off. Tapping anywhere on the description opens or closes it. A description that fits shows in full, with no words under it and no tap.
- **Find Shows heading:** the country name is in the accent color, like the chevron next to it. When the heading is plain text (the phone's region is the United States), nothing changes.
- **Settings:** "What's New" in the About row is in the accent color, the way iOS shows a row that does something when you tap it. The version stays as it is.
- The three backlog entries go.
- Version 0.5.1, a fix. It ships after 0.5 (follow-star-spin), which isn't committed yet.

## Out of scope

- How the description is cleaned of HTML.
- Other rows in Settings.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `show-page`: the Show header requirement says Show more and Show less, only when the description is cut off, and the whole description toggles it.
- `discovery`: the Chart country requirement says the country name is in the accent color.
- `whats-new`: the Version in Settings requirement says What's New is in the accent color.

## Impact

- `Casterr/Screens/ShowView.swift`: the description in the header, and its loading placeholder.
- `Casterr/Screens/DiscoverView.swift`: `popularHeading`.
- `Casterr/Screens/SettingsView.swift`: the About row.
- `CasterrUITests/ScreensTests.swift`: a check for Show more.
- `CHANGELOG.md`, `project.yml`, `BACKLOG.md`, `openspec/device-checks.md`.
