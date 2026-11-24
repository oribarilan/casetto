## Why

Every build is version 0.1, so neither the listener nor TestFlight shows what changed or which build is which. Now that builds go out through TestFlight, each one should carry its own number and say what's new.

## What Changes

- Every commit that changes the app for the listener bumps the version: the minor number for new behavior (0.2 to 0.3), the patch number for fixes only (0.3 to 0.3.1). Commits that only touch specs, the backlog or tooling don't bump it. The build number stays the upload time.
- `CHANGELOG.md` in the repository gets one section per version, written in the listener's words, added in the same commit as the bump. The app bundles it.
- On the first launch after an update, Cassy says "I learned some new tricks." with See, which opens What's New: every version newer than the last one seen, newest first. A first install shows the welcome screen instead.
- Settings ends with an About section: "Version 0.3 (202611241530)", which opens What's New with every version.
- `scripts/testflight.sh` refuses to upload when the changelog's top version doesn't match the app's version.
- `AGENTS.md` gets the rule for agents.
- The first versioned build is 0.2: it lists what changed since the first TestFlight build.

## Capabilities

### New Capabilities
- `whats-new`: version numbers, the changelog, What's New after an update, and the version in Settings.

### Modified Capabilities
- None.

## Impact

`project.yml` (MARKETING_VERSION in both targets), new `CHANGELOG.md` bundled as a resource, a small changelog parser in CasterrCore with tests, a What's New sheet, launch logic in AppModel, Settings, `scripts/testflight.sh`, `AGENTS.md`.
