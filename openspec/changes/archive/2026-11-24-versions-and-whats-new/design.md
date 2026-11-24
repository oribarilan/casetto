## Context

`project.yml` sets `MARKETING_VERSION: "0.1"` in two targets and `CURRENT_PROJECT_VERSION: "1"`; `scripts/testflight.sh` overrides the build number with the time. Cassy's toast (`AppModel.cassyToast`, `CassyMessage` with an action) already shows launch messages. `RootView` keeps `hasSeenOnboarding` in AppStorage. Settings is a grouped List of Sections.

## Goals / Non-Goals

**Goals:** a real version on every build, a changelog people can read, a light What's New, the version in Settings.

**Non-Goals:** release notes in App Store Connect, git tags per version, a What's New sheet that opens by itself.

## Decisions

- **One source for the version:** `MARKETING_VERSION` in `project.yml`, both targets. The app reads `CFBundleShortVersionString`. The changelog's top heading must match, checked by `testflight.sh` with a grep, not by the app.
- **Changelog format:** `# Changelog`, then `## 0.3` sections with `- ` lines. `ChangelogParser` in CasterrCore turns the text into `[Release(version, lines)]` and picks the releases newer than a given version, comparing numbers part by part (0.10 is newer than 0.9). Tested in the core.
- **Bundling:** `CHANGELOG.md` from the repo root is listed as a resource of the app target in `project.yml`, so there's one file.
- **Last seen version:** AppStorage `lastSeenVersion`. At launch: if it's empty and onboarding isn't done, store the current version silently (first install). If it differs from the current version, show the toast, then store it. An install from before this change (onboarding done, nothing stored) shows the toast with only the current version.
- **What's New view:** a sheet with a List: one section per version, the lines as plain rows, a Done button. The same view opens from Settings with every version.
- **Toast:** job `.success`, text "I learned some new tricks.", action title "See". It waits until the welcome and the first refresh toast are past, by showing after the Queue appears.
- **Rule for agents:** a short section in `AGENTS.md`: bump and changelog in the same commit as any listener-facing change; minor for behavior, patch for fixes; none for specs, backlog or tooling.

## Risks / Trade-offs

- Many small versions (0.2, 0.3, 0.4...) because every feature commit bumps. That's the chosen trade: each build is precise, and What's New groups skipped versions.
- Forgetting the bump: the TestFlight script catches a changelog that doesn't match, but not a missing bump with a matching entry. The AGENTS.md rule covers that.
