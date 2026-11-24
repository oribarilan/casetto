## 1. Changelog

- [x] 1.1 Add `ChangelogParser` to CasterrCore: parse sections, and list releases newer than a version, comparing part by part
- [x] 1.2 Add tests: parsing, newer-than with skipped versions, 0.10 after 0.9, unknown last version
- [x] 1.3 Write `CHANGELOG.md` with 0.1 (first TestFlight build) and 0.2 (changes since: Now Playing pause meter, clip waveform, Download on cellular, download size, What's New), and bundle it in `project.yml`
- [x] 1.4 Set `MARKETING_VERSION` to 0.2 in both targets

## 2. App

- [x] 2.1 Add the What's New sheet
- [x] 2.2 Show Cassy's toast on the first launch after an update, with `lastSeenVersion`, silent on first install
- [x] 2.3 Add the About section at the end of Settings with the version and build, opening What's New

## 3. Tooling and docs

- [x] 3.1 Make `scripts/testflight.sh` stop when the changelog's top version isn't the app's version
- [x] 3.2 Add the versioning rule to `AGENTS.md`
- [x] 3.3 Add phone checks to `openspec/device-checks.md` and remove the backlog entry
- [x] 3.4 Run the core and UI tests
