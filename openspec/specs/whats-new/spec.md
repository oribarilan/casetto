# whats-new Specification

## Purpose
Every listener-facing change carries a version and a line in the changelog, and the listener hears what changed after an update.

## Requirements

### Requirement: Version numbers
The app's version SHALL go up with every commit that changes what the listener sees or hears: the minor number for new behavior, the patch number for fixes only. Commits that change only specs, the backlog or tooling MUST NOT change it. The build number SHALL stay the upload time.

#### Scenario: New behavior
- **WHEN** a commit adds a feature to version 0.2
- **THEN** the version becomes 0.3

#### Scenario: Fix only
- **WHEN** a commit only fixes a bug in version 0.3
- **THEN** the version becomes 0.3.1

#### Scenario: Specs only
- **WHEN** a commit only archives OpenSpec changes
- **THEN** the version stays the same

### Requirement: Changelog
`CHANGELOG.md` SHALL have one section per version, newest first, each a "## 0.3" heading with one line per change in the listener's words, added in the same commit as the bump. The app MUST bundle it and read What's New from it. An upload to TestFlight MUST refuse to run when the top section doesn't match the app's version.

#### Scenario: Mismatch
- **WHEN** the app is version 0.4 and the changelog's top section is 0.3
- **THEN** `scripts/testflight.sh` stops before archiving and says the two differ

### Requirement: What's New after an update
On the first launch after the version changes, Cassy SHALL say "I learned some new tricks." with See. See MUST open What's New, listing every version newer than the last one seen, newest first, with its lines. It MUST show once per update. A first install MUST NOT show it; the welcome screen comes first.

#### Scenario: One update
- **WHEN** the listener opens version 0.3 for the first time after using 0.2
- **THEN** Cassy says "I learned some new tricks." and See opens What's New with the 0.3 lines

#### Scenario: Skipped versions
- **WHEN** the listener updates from 0.2 straight to 0.5
- **THEN** What's New lists 0.5, 0.4 and 0.3, newest first

#### Scenario: First install
- **WHEN** the listener opens Casterr for the first time
- **THEN** the welcome screen shows and Cassy says nothing about new tricks

#### Scenario: Second launch
- **WHEN** the listener opens 0.3 again after Cassy already told them
- **THEN** Cassy says nothing about new tricks

### Requirement: Version in Settings
Settings SHALL end with an About section showing the version and build. Tapping it MUST open What's New with every version, newest first.

#### Scenario: Version in Settings
- **WHEN** the listener opens Settings on version 0.3
- **THEN** the last section reads "Version 0.3" with the build number, and tapping it opens What's New with every version, newest first
