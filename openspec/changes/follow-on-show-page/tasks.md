## 1. Follow wording

- [x] 1.1 Change every label the app shows from Subscribe, Subscribing, Unsubscribe, Subscribed, and "Casterr Subscriptions" to Follow, Following, Unfollow, Followed, and "Casterr Shows"; add Follow to the word list in `podcast_app_concept.md`; update the UI tests that tap those labels

## 2. Show page buttons

- [x] 2.1 Add Follow/Following and Star/Starred under the show page header for followed and unfollowed shows, confirm before unfollowing, remove Unsubscribe from the ⋯ menu and the big Subscribe button; add a UI test that stars and unfollows from the page

## 3. Open shows from Find Shows

- [x] 3.1 Add a `FeedService` call that fetches and saves a show's feed without following it, reusing what Apple Podcasts links do, with a core test
- [x] 3.2 Make a Find Shows row open the show page, which fetches the feed when the device doesn't have it; add a UI test that opens a show from Find Shows and sees its episodes and Follow
- [x] 3.3 Run all core tests and all UI tests once
