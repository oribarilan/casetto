# Tasks

## 1. Placeholders

- [x] 1.1 Turn `ArtShimmer` into a shared `Shimmer` view with a `PlaceholderBar`, still at Reduce Motion, and use it in `ArtworkView`
- [x] 1.2 Add the placeholder header and four placeholder episode rows to `ShowView`, in place of the spinner, hidden from VoiceOver behind one "Loading episodes" label

## 2. Directory details

- [x] 2.1 Route Find Shows with the `DirectoryShow`, and show its name, host and art in the header until the feed arrives, keeping its art after
- [x] 2.2 Add a UI test that opens a show from Find Shows and finds its title before its episodes, and take before and after screenshots

## 3. Wrap up

- [x] 3.1 Set `MARKETING_VERSION` to 0.3.1, add the 0.3.1 section to `CHANGELOG.md`, remove the backlog entry, and add a phone check to `openspec/device-checks.md`
- [x] 3.2 Run the core and UI tests, and install on the phone
