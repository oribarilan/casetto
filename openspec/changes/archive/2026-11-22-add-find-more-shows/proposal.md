# Proposal

## Why

Once you follow a show, the popular list is gone: the Shows tab shows only your grid, and you can find new shows only by typing a name. The popular list also only covers your own region, so someone in Israel can't browse what's popular in the United States.

This isn't a roadmap milestone. It extends onboarding and discovery from M5.

## What Changes

- **Find Shows in the + menu:** the Shows tab's + menu gets "Find Shows" as its first item. It opens the same Find Shows screen as onboarding (popular shows, search, Subscribe and Star) as a sheet, without the welcome screen, closed with Done.
- **Popular shows in an empty search:** tapping the Shows tab's search field shows the popular shows before you type anything. Typing replaces them with results, as today.
- **Chart country:** when the phone's region isn't the United States, the "Popular now · Israel" heading becomes a menu with the region and United States. The choice is kept on this phone, and search uses the same country. When the region is the United States, or the phone has no region, the heading stays plain text.
- `podcast_app_concept.md`: the suggestions bullet says where Find Shows lives after onboarding and that the chart can switch to the United States.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `discovery`: top shows follow a chart country the listener can switch to the United States; search uses that country and an empty search shows the popular shows; Find Shows opens from the + menu after onboarding.

## Out of scope

- A worldwide chart. Apple has none: every chart belongs to one country's store, and made-up codes like `ww` return errors. A mix of several stores' charts would put many languages in one list and rank shows by our own rule instead of Apple's.
- Countries other than the phone's region and the United States.
- Syncing the chart country to other devices. It's a browsing choice, kept on the phone like the tips.
- Genres, personal picks, or other new suggestions.

## Impact

- `Casterr/Screens/ShowsView.swift`: the + menu item and its sheet, and popular shows while the search field is active and empty.
- `Casterr/Screens/DiscoverView.swift`: the Find Shows screen pulled out of `OnboardingView` so the sheet reuses it, the heading menu, and the chart country passed to the directory.
- `CasterrCore` `AppleDirectory`: no change; `topShows` and `search` already take a country.
- UI tests for the + menu sheet, the empty search, and the heading menu.
