# Tasks

## 1. Controls

- [x] 1.1 Give `NewEpisodesSheet` `@State` copies of the level and the override, start them from the show page's values, and set them on tap before saving
- [x] 1.2 Make Star on the show page and in Find Shows flip at once, without dimming, and roll back if the save fails
- [x] 1.3 Make Follow on the show page and in Find Shows show Following at once while the feed downloads, and go back to Follow with the error if it fails
- [x] 1.4 Make the Settings pickers for Remove unplayed episodes after, Keep downloaded, and Default speed set their value before saving

## 2. Tests

- [x] 2.1 Add UI checks that a sheet tile, Star, Follow, and a Settings picker show their new state within half a second

## 3. Wrap up

- [x] 3.1 Set `MARKETING_VERSION` to 0.4.1, add the 0.4.1 section to `CHANGELOG.md`, remove the two backlog entries, and add phone checks to `openspec/device-checks.md`
- [x] 3.2 Run the core and UI tests, and install on the phone
