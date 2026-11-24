# Design

## Context

`ShowView` reads the show from `Library`. For a show from Find Shows that the phone doesn't have, `fetchFeedIfMissing` previews the feed, and until it lands `show` is nil, so `header` draws nothing and a `ProgressView` stands in for the list. `ArtworkView` already shimmers with a private `ArtShimmer`. Find Shows routes with `Route.directoryShow(URL)`, though it holds a `DirectoryShow` with title, author, 600-pixel art and feed address.

## Decisions

**A shared `Shimmer` view in `Theme.swift`.** The private `ArtShimmer` becomes `Shimmer`, still gray and still at Reduce Motion, and a `PlaceholderBar` clips it to a capsule for lines of text. `ArtworkView` uses it, and so do the new bars. One look for every placeholder. The other option, `.redacted(reason: .placeholder)`, draws gray bars but doesn't shimmer, and bars sized by fake text change width with the font.

**The route carries the directory entry.** `Route.directoryShow(DirectoryShow)`; `DirectoryShow` is already `Hashable`. `ShowView` gets `var preview: DirectoryShow?`. The header uses `show` when it's loaded and `preview` until then, field by field: the title and author come from `show ?? preview`, the description only from `show`. The art URL is `preview?.artworkURL ?? show?.artworkURL`, so a Find Shows page never swaps its picture.

**Placeholder layout matches the real one.** The header placeholder uses the same 120-point art size and stack as the real header: a title bar, a shorter author bar, and two description lines, the second shorter. Four placeholder rows use `EpisodeRow`'s art size and three bars (status, title, date). They show while `fetchingFeed && episodes.isEmpty`, where the spinner is today. They're hidden from VoiceOver, and the list keeps one "Loading episodes" label for it.

## Risks / Trade-offs

- [The directory's title or art can differ a little from the feed's] → The title switches to the feed's when it arrives. The art stays the directory's, which is the same show's picture.
- [A feed that never arrives leaves the placeholders up] → The same as today's spinner; the existing error line appears on failure.
