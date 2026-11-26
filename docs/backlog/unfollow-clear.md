# Clear a show when unfollowing: findings

Investigated 2026-11-26 by reading the code and specs, plus a short web search. Nothing was built or run. The code paths and spec text are verified. What happens to the episode playing now, and to downloads, is inferred from the code.

## What unfollowing does today (verified in code)

Unfollowing clears only the show's Inbox episodes and the show's settings. The Queue, downloads, bookmarks, listening progress and the episode playing now are left alone.

- **Entry points:** the Following button on the show page (`ShowView.swift:219`, `unfollow()`, which also keeps the feed address so Follow can come back), Unfollow on an Inbox rule card with no confirmation (`InboxView.swift:190`), and the Follow toggle in Find Shows, also with no confirmation (`DiscoverView.swift:238`).
- All three call `FeedService.unsubscribe` (`FeedService.swift:124`), which calls `Library.removeSubscription` (`Library.swift:169-177`).
- **Settings:** deleting the subscription drops the level, the star, the speed and voice boost overrides, the expiry override, and the rule card dates (`Models.swift:48-64`).
- **Inbox:** the show's Inbox episodes move to the archive with the reason "unsubscribed" (`Library.swift:173`).
- **Queue:** untouched. The Queue keeps any episode whose record still exists (`Library.swift:396-400`). Tests: `StorageTests.swift:48`, `FeedServiceTests.swift:255`.
- **Downloads:** unfollowing deletes no files itself. Download sync keeps only the top Queue episodes and deletes other files (`AppModel.swift:155-166`, `DownloadPlan.swift:5-20`), and Inbox episodes are rarely downloaded.
- **Bookmarks, progress, show and episode records:** untouched. Bookmarks must survive (`openspec/specs/capture/spec.md:16`).
- **The episode playing now:** no unfollow code touches playback, so it should keep playing. Inferred.
- **Refresh** stops for the show, because refresh walks the subscriptions.
- **Following again** starts fresh at Inbox, with no old settings.

## What the specs and concept say

- `openspec/specs/subscriptions/spec.md:46-47`: "Episodes of that show that are in the Queue MUST stay in the Queue. Episodes ... in the Inbox MUST move to the archive with the reason 'unsubscribed'."
- `openspec/specs/show-page/spec.md:56`: tapping Following must ask to confirm, then unfollow, and the page's menu must not hold Unfollow.
- `openspec/specs/show-page/spec.md:72`: the question says "Episodes you queued stay in your Queue."
- `podcast_app_concept.md:106`: "Unsubscribing clears the show's Inbox episodes. Anything you queued stays, and so do bookmarks and history."
- `openspec/specs/discovery/spec.md:35`: a second tap on Follow in Find Shows unfollows with no question. So only the show page asks.

The backlog item changes a promise the app makes today: the show page tells the listener their queued episodes stay.

## Other apps (thin results)

- **Apple Podcasts:** unfollowing a show with downloads asks whether to keep or remove them. Keeping them stops new downloads and deletes nothing ([support.apple.com/en-us/127830](https://support.apple.com/en-us/127830)). It says nothing about Up Next.
- **Pocket Casts:** no official statement found. Episodes leave the queue one at a time, or with Clear All, which asks first when more than two are queued.
- **Overcast:** nothing found.

## Flows, simplest first

- **(a) Silent:** unfollowing also removes the show's Queue episodes and downloads, with no new question. The episode playing now plays to its end, and bookmarks stay. It breaks "Anything you queued stays" in the concept and the spec, and a surprise loss is hard to undo because the app has no Undo.
- **(b) A second button in the question:** the show page's question offers "Unfollow" or "Unfollow and remove N queued episodes". The episode playing now stays until it ends. The rule card and Find Shows don't ask, so they keep today's behavior, and the paths differ. It costs one button and a changed spec line (`show-page/spec.md:72`).
- **(c) Today's behavior, plus a "Remove from Queue" item in the show page's menu:** the same data change as (b), but a new control, and more interface than (b).

## Recommendation

Build none of these yet. Queued episodes already leave the Queue one at a time with the row's Remove action. If a single step is still wanted, choose (b), on the show page only. In the app, say Remove, not "clear": Remove is the word the Words table uses.

## A freeze around unfollowing (reported 2026-11-26)

The listener saw the app freeze when they unfollowed a show, and had to force close and reopen it. It didn't happen again, and it may not come from the unfollow itself. The unfollow's database work runs on the library's own queue, not the main thread (`Library.swift:169-177`), so the freeze more likely came from the screens updating afterward. Not investigated further: no crash or hang report could be read, because the phone wasn't reachable.

If it happens again:

- Turn on Settings > Developer > Hang Detection on the phone, so iOS records hangs with their logs.
- Before reopening the app, connect the phone and ask for the hang to be read. Its reports are under Settings > Privacy & Security > Analytics & Improvements > Analytics Data, with names starting "Casterr".
- Note what was on screen and what was playing.
