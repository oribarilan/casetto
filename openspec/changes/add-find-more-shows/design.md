# Design

## Context

`OnboardingView` wraps `DiscoverView` in a NavigationStack with a large "Find Shows" title, a search field in the navigation bar, and Skip or Done. `ShowsView` shows `DiscoverView` only when you follow nothing or have typed a search. `AppleDirectory.topShows` and `search` already take a country and default to the phone's region.

## Decisions

- **One Find Shows screen.** Move `OnboardingView`'s `findShows` into a `FindShowsView` that takes `inOnboarding` and a close action. Onboarding uses it with Skip or Done; the + menu's sheet uses it with Done. No second copy of the screen.
- **Empty search uses `searchable(isPresented:)`.** `ShowsView` shows `DiscoverView` when the search is active, not only when the query has text. `DiscoverView` already shows the top shows for an empty query. Cassy's "Let's add some shows!" card stays above the list, as on every Find Shows screen, so there's one rule for when she shows.
- **The chart country is an `@AppStorage` string, read by `DiscoverView`.** It holds `us` or nothing; nothing means the phone's region. Storing only the United States choice means a phone that changes region follows the new region. It stays on the device, like the tips, because it's a browsing choice and not listening data, so it isn't part of the synced Settings.
- **The heading menu is a SwiftUI `Menu` as the section header,** with a check on the current choice. It's plain text when the region is `us` or missing.

## Risks / Trade-offs

- Search in the United States store can miss a show only sold in the region's store. That's rare for podcasts, and switching back is one tap.
