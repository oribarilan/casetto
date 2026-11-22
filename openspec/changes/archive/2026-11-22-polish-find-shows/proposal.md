# Proposal

## Why

On the phone, the Shows tab's search mixing your shows with the directory, and showing the popular list before you type, made the tab do two jobs. Finding new shows belongs in Find Shows, which the + menu now opens. Switching the chart country keeps the old list on screen with no sign that the new one is loading. And nothing is kept on the phone: popular lists download again on every visit, and show art can reload or go missing offline.

This isn't a roadmap milestone. It adjusts `add-find-more-shows`.

## What Changes

- The Shows tab's search filters only the shows you follow, in the grid, by title and author. It no longer lists directory shows, and an empty search shows your grid as it is. With no match, it says so.
- While you follow nothing, the Shows tab is still Find Shows, and its search still covers the directory.
- Picking a chart country with no saved list clears the list and shows the loading Cassy ("Flipping through the shelves…") until the new chart arrives.
- **Saved charts:** the phone keeps the last top 25 of your region and of the United States. Find Shows shows the saved list at once, then swaps in the fresh one when it arrives. Opening Find Shows fetches both, so switching is usually instant. If a fresh chart fails, the saved list stays.
- **Saved show art:** art is kept on the phone once loaded and shown from there, without checking the server again: for shows you follow, the saved charts, and everywhere else art appears. It shows offline too.
- **Clear Cache:** a Storage section in Settings shows how much space saved art and popular lists take, with a Clear Cache button. Downloaded episodes, bookmarks, and shared files stay.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `subscriptions`: "Search your shows" lists only followed shows.
- `discovery`: search of the directory happens in Find Shows; switching to a country with no saved chart shows the loading state; new requirement for saved charts.
- `look-and-feel`: new requirement that show art is kept on the phone.
- `settings`: Settings holds Clear Cache besides the global defaults.

## Out of scope

- Any change to Find Shows' layout, its + menu entry, or the chart country menu.
- Saving search results, or more than 25 shows per chart.
- Refreshing art that changed on the server at the same address. Feeds almost always give new art a new address.

## Impact

- `Casterr/Screens/ShowsView.swift`: filter the grid while searching; no directory results; drop the empty-search popular list.
- `Casterr/Screens/DiscoverView.swift`: drop the "Your shows" section and `FollowedShow`; show the saved chart first; clear results only when switching to a country with no saved chart.
- `CasterrCore`: saving and reading the last chart per country, a small file in the app's caches.
- `ArtworkView`: loads art cache-first through the existing 300 MB download cache, with a memory cache so lists don't flicker.
- `Casterr/Screens/SettingsView.swift`: the Storage section.
- UI tests: `testFindMoreShows` checks that the Shows search finds only your shows; `testChartCountry` checks the switch; a core test covers saving and reading a chart.
