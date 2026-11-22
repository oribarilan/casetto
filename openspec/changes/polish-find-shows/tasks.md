## 1. Shows search

- [x] 1.1 Make the Shows tab's search filter the grid with `ShowSearch.matches`, show `ContentUnavailableView.search` with no match, keep Find Shows when following nothing, and remove the "Your shows" section and `FollowedShow` from `DiscoverView`; change `testFindMoreShows` to search "planet" and see only Planet Money with no Star buttons

## 2. Saved charts and loading

- [x] 2.1 Add saving and reading the last chart per country to `CasterrCore` (a JSON file in the caches directory), with a core test that saves a chart and reads it back
- [x] 2.2 In `DiscoverView`, show the saved chart at once, fetch the region and United States charts on open, keep the saved list when a fetch fails, and show the loading Cassy only when the chart country has no saved list; in `testChartCountry`, check that after one visit the United States chart appears at once after switching

## 3. Saved show art

- [x] 3.1 Load art in `ArtworkView` cache-first (`returnCacheDataElseLoad` through `URLCache.shared`) with an in-memory image cache, and warm the art of both saved charts; check on the simulator that the Shows grid shows art with the network off
- [x] 3.2 Add a Storage section to Settings with Clear Cache and the cache's size, emptying `URLCache.shared`, the in-memory images, and the saved charts; add a UI test that taps it and sees the size drop

## 4. Checks

- [x] 4.1 Run all core tests and all UI tests once
