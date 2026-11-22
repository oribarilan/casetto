## 1. Find Shows after onboarding

- [x] 1.1 Move `OnboardingView`'s Find Shows screen into `FindShowsView(inOnboarding:close:)` and use it from onboarding; verify `testOnboarding` still passes
- [x] 1.2 Add "Find Shows" as the first item of the Shows tab's + menu, opening `FindShowsView` as a sheet with Done; add a UI test that opens it with shows followed, sees the top shows, and closes it with Done
- [x] 1.3 Show the top shows while the Shows tab's search field is active and empty, through `searchable(isPresented:)`; add a UI test that taps the empty search with shows followed and sees "Popular now"

## 2. Chart country

- [x] 2.1 Keep the chart country in `@AppStorage` (`us` or nothing for the phone's region), pass it to `topShows` and `search`, and make the Popular now heading a menu with the region and United States, plain text when the region is the United States or missing; add a UI test, launched with `-AppleLocale en_IL`, that switches to United States, sees "Popular now · United States", and finds it still chosen after reopening Find Shows

## 3. Docs and checks

- [x] 3.1 Update the suggestions bullet in `podcast_app_concept.md`; run all core tests and all UI tests once
