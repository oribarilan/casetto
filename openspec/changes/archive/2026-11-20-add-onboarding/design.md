# Design

## Context

Subscribing works by feed address and OPML. Apple's documented chart (`rss.marketingtools.apple.com/api/v2/{country}/podcasts/top/{n}/podcasts.json`) returns Apple IDs, names, authors, and artwork, but no feed addresses. The iTunes lookup endpoint (`itunes.apple.com/lookup?id=…&entity=podcast`) returns `feedUrl` for up to many IDs in one call. The search endpoint (`itunes.apple.com/search?media=podcast&term=…`) returns `feedUrl` directly. None need a key. Search allows about 20 calls a minute. I checked all three against the live endpoints.

## Decisions

### D1. One directory struct

`AppleDirectory(session:)` in `CasterrCore`:
- `topShows(country:limit:)` fetches the chart, then one lookup call for its IDs, and returns `[DirectoryShow]` in chart order, without shows that have no feed address.
- `search(_:country:)` returns up to 25 shows.
- `DirectoryShow` holds the Apple ID, title, author, artwork URL, and feed URL.

The country is the device region, lowercased, falling back to `us`. The concept doc called for a provider interface; one implementation doesn't need a protocol, so it waits for a second directory.

### D2. Debounce with the view task

The search field drives `.task(id: query)`, which sleeps 400 ms before searching. Typing cancels the task, so only a pause sends a request.

### D3. One Discover view

`DiscoverView` lists either search results (when the query isn't empty) or the top shows. Each row has Subscribe and Star buttons:
- Subscribe calls `FeedService.subscribe`. On a subscribed show it unsubscribes.
- Star subscribes when needed, then sets the level to Auto-queue. On a starred show it sets Inbox.

Subscribing with a star runs triage at the Inbox level first, so the newest episode goes to the Inbox and then stays there when the level changes. To make starring queue the newest episode as the spec says, Star sets the level before triage: `FeedService.subscribe(to:level:)` gains a level parameter that defaults to Inbox.

It shows in three places:
- Onboarding: a full-screen cover on launch when the listener follows nothing and `hasSeenOnboarding` (an `@AppStorage` flag, per device) is false. Done and Skip set the flag.
- The Shows tab when the listener follows nothing.
- The Shows tab's search: `.searchable` on Shows swaps the list for `DiscoverView` while the query isn't empty.

### D4. Tabs

`RootView` is a `TabView` with Queue and Shows, each with its own `NavigationStack` and the `Route` destinations. `AppModel.tab` holds the selection, so the empty Queue's "Your Shows" button can switch tabs. The mini player moves to `tabViewBottomAccessory(isEnabled:)`, which iOS 27 provides for this.

### D5. OPML export

`OPMLWriter.write(_:)` builds OPML 2.0 with escaped titles and feed addresses. The Shows menu gets a `ShareLink` whose item is a `Transferable` that writes the file on demand, named "Casterr Subscriptions.opml".

## Risks / Trade-offs

- [Chart shows missing from the lookup] → They are left out, so the list can have fewer than 25 shows.
- [The chart has no genres] → Search covers specific interests.
- [UI tests start with an onboarding cover] → The tests pass `-hasSeenOnboarding YES`, which sets the flag through the arguments domain of `UserDefaults`. One test passes `NO` to check onboarding.

## Migration Plan

No data changes. Existing listeners already follow shows, so they never see onboarding.
