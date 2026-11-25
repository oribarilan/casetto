# Proposal

## Why

The show page's Follow and Star are two big tangerine capsules side by side. They're loud, and the listener finds them unpolished. They picked option B, "One primary": Follow is the only tangerine capsule, and Star sits beside it as a round icon button.

The "New episodes" row under them reads like a link to the show's new episodes, but those are in the list below. The row is really the rule for where new episodes go. It also pops in after the follow saves, which can take a few seconds because following fetches the feed first. The listener picked option 2, "A menu in the row", and wants the row to appear and change without a jump.

This is a backlog item, not a numbered roadmap milestone.

## What Changes

- **Follow** is a tangerine capsule. Once followed it turns grey and reads Following.
- **Star** is a round icon button next to Follow, with a star or a filled star. VoiceOver still reads Star or Starred.
- **The New episodes row** reads "New episodes go to" with the choice on the right (Inbox, Queue, Play next or Skip) and an up-down chevron. Tapping it opens a menu in place. Each choice keeps its short explanation: Inbox "Wait for me to decide", Queue "Add to the end", Play next "Right after what's playing", Skip "Only on this page".
- **When the choice is Inbox**, a second row reads "Removed after" with the period (for example 14 days). Its menu lists My default and the presets 1, 3, 7, 14 and 30 days and Never.
- **The new-episodes sheet goes away.** The two menus cover everything it did.
- **No jump.** The row appears the moment the listener taps Follow or Star, without waiting for the save. It grows in and out, and the episode list slides with it. A changed choice cross-fades. With Reduce Motion on, the row appears and changes without movement.
- Version 0.6.

## Out of scope

- Follow and Star in Find Shows. They stay as they are.
- The per-show speed row and the rest of the show page.
- The wording of the global Inbox period in Settings.
- Haptics.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `show-page`: the Follow and Star look, the New episodes row as two menus in place of a sheet, and the row appearing at once and smoothly.

## Impact

- `Casterr/Screens/ShowView.swift`: the buttons, the row and its menus, and showing the follow's level before the save lands.
- `Casterr/Screens/NewEpisodesSheet.swift`: deleted. Its `InboxExpiry.shortTitle` helper moves to `SettingsView.swift`, which still uses it.
- `CasterrUITests/ScreensTests.swift`: tests that open the sheet use the menus instead.
- `CHANGELOG.md` and `project.yml`: version 0.6.
- `openspec/device-checks.md`: how the row grows and how the buttons look on the iPhone.
