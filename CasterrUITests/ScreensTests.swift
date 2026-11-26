import XCTest

/// Walks the screens against their spec scenarios and saves a screenshot of each.
/// Needs network: it subscribes to a real public feed.
final class ScreensTests: XCTestCase {
    private let feed = "https://feeds.npr.org/510289/podcast.xml"
    private var app: XCUIApplication!

    @MainActor
    func testScreens() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()

        // Queue is the home screen; empty state links to shows.
        XCTAssertTrue(app.staticTexts["Silence. Lovely, but let's fix that."].waitForExistence(timeout: 5))
        snapshot("1 Empty Queue")
        app.buttons["Find Shows"].tap()
        XCTAssertTrue(waitForTopShows())

        // Follow by RSS URL: error messages, then success.
        subscribe(to: "https://example.com/")
        XCTAssertTrue(app.staticTexts["That address isn't a podcast feed."].waitForExistence(timeout: 20))
        snapshot("2 Not a Podcast")
        app.buttons["Cancel"].tap()
        subscribe(to: "https://nonexistent.invalid/feed.xml")
        XCTAssertTrue(app.staticTexts["Couldn't reach that feed. Check the address and your connection."].waitForExistence(timeout: 20))
        app.buttons["Cancel"].tap()
        subscribe(to: feed)
        let show = app.buttons["Planet Money, NPR"]
        XCTAssertTrue(show.waitForExistence(timeout: 30))
        snapshot("3 Shows")

        // Search covers only your shows.
        let search = app.searchFields["Search shows"]
        search.tap()
        search.typeText("planet")
        XCTAssertTrue(show.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["More shows"].exists)
        snapshot("3b Search")
        app.buttons["Close"].tap()

        // Show page: add three episodes to the Queue, mark the third played.
        show.tap()
        let episodes = app.buttons.matching(identifier: "episode")
        XCTAssertTrue(episodes.firstMatch.waitForExistence(timeout: 10))
        // Scroll a little so all three rows sit above the floating up-next bar.
        let list = app.collectionViews.firstMatch
        list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
            .press(forDuration: 0, thenDragTo: list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42)))
        // A tap opens the row's actions: Play Next queues the third episode, swipes add the first two.
        episodes.element(boundBy: 2).tap()
        XCTAssertTrue(app.buttons["Play Next"].waitForExistence(timeout: 5), "no action line")
        snapshot("4a Row Actions")
        app.buttons["Play Next"].tap()
        for index in 0..<2 {
            episodes.element(boundBy: index).swipeRight()
            app.buttons["Add to Queue"].tap()
        }
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Queued'")).firstMatch.waitForExistence(timeout: 5))
        // Played in the line folds the third away.
        episodes.element(boundBy: 2).tap()
        app.buttons["Played"].tap()
        // Played episodes fold into a row above the list.
        XCTAssertTrue(app.staticTexts["Played"].waitForExistence(timeout: 5))
        snapshot("4 Show Page")

        // Star from the page sends an Inbox show's new episodes to the Queue; unstarring keeps that.
        let star = app.buttons["starShow"]
        XCTAssertEqual(star.label, "Star")
        star.tap()
        XCTAssertTrue(app.buttons["Starred"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["newEpisodesRow"].waitForValue("Queue"))
        star.tap()
        XCTAssertTrue(star.wait(for: \.label, toEqual: "Star", timeout: 5), "still starred")
        sleep(1)
        XCTAssertEqual(app.buttons["newEpisodesRow"].value as? String, "Queue", "unstarring changed the setting")

        // Unfollow asks first, keeps queued episodes, and leaves the page with Follow.
        let follow = app.buttons["followShow"]
        XCTAssertEqual(follow.label, "Following")
        follow.tap()
        app.buttons.matching(identifier: "Unfollow").element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Follow"].waitForExistence(timeout: 5), "the page lost Follow after unfollowing")
        XCTAssertFalse(app.buttons["newEpisodesRow"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(waitForTopShows())
        app.tabBars.buttons["Queue"].tap()

        // Queue: two items in the order added; remove the second.
        let queue = app.buttons.matching(identifier: "queueItem")
        XCTAssertTrue(queue.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(queue.count, 2)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Up next'")).firstMatch.exists)
        // Nothing plays yet, so the bar offers the first Queue episode as new, not as continue.
        let upNext = app.buttons["upNextBar"]
        XCTAssertTrue(upNext.waitForExistence(timeout: 5))
        XCTAssertTrue(upNext.label.hasPrefix("Up next"), upNext.label)
        snapshot("5 Queue")

        // The first two rows have no Play Next, where it would change nothing. Tapping another row moves the line
        // there, and tapping it again closes it.
        queue.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Show"].waitForExistence(timeout: 5), "no action line")
        XCTAssertFalse(app.buttons["Play Next"].exists, "Play Next on the first row")
        queue.element(boundBy: 1).tap()
        XCTAssertTrue(app.buttons["Played"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Play Next"].exists, "Play Next on the second row")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label == 'Show'")).count, 1, "two lines open")
        snapshot("5a Queue Row Actions")
        queue.element(boundBy: 1).tap()
        XCTAssertTrue(app.buttons["Show"].waitForNonExistence(timeout: 5), "the line didn't close")

        // Long-press and drag reorders without an Edit button.
        let firstBefore = queue.element(boundBy: 0).label
        queue.element(boundBy: 1).press(forDuration: 1.5, thenDragTo: queue.element(boundBy: 0),
                                        withVelocity: .slow, thenHoldForDuration: 0.8)
        XCTAssertTrue(queue.element(boundBy: 1).waitForExistence(timeout: 5))
        XCTAssertTrue(queue.element(boundBy: 1).label.contains(firstBefore.components(separatedBy: ", ").dropFirst().first ?? "?"),
                      "first: \(queue.element(boundBy: 0).label)")
        queue.element(boundBy: 1).swipeLeft()
        app.buttons["Remove"].tap()
        XCTAssertEqual(queue.count, 1)

        // Downloads: the top of the Queue downloads on Wi-Fi, and Off deletes it.
        let downloaded = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Downloaded'")).firstMatch
        XCTAssertTrue(downloaded.waitForExistence(timeout: 120))
        snapshot("5b Downloaded")
        app.navigationBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Off"].waitForExistence(timeout: 5))
        // The size line follows the choice, and Off has none.
        let estimate = app.staticTexts["downloadEstimate"]
        XCTAssertTrue(estimate.waitForExistence(timeout: 5), "no download size line")
        XCTAssertTrue(estimate.label.hasSuffix("for the top 3."), estimate.label)
        snapshot("5c Download Size")
        app.buttons["Off"].tap()
        XCTAssertTrue(estimate.waitForNonExistence(timeout: 5), "Off still shows a size")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(downloaded.waitForNonExistence(timeout: 10))

        // Now Playing: play from the bar, sleep timer.
        app.buttons["upNextPlay"].tap()
        let miniPlayer = app.buttons["miniPlayer"]
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Playing"].waitForExistence(timeout: 10))
        miniPlayer.tap()
        app.buttons["Sleep timer"].tap()
        app.buttons["15 minutes"].tap()
        let timer = app.buttons["Sleep timer"]
        let counting = NSPredicate(format: "value BEGINSWITH 'Pauses at'")
        expectation(for: counting, evaluatedWith: timer)
        waitForExpectations(timeout: 5)
        snapshot("6 Now Playing")
        // The sheet marks the running timer and offers Turn Off.
        timer.tap()
        XCTAssertTrue(app.buttons["Turn Off"].waitForExistence(timeout: 5), "no Turn Off for a running timer")
        XCTAssertTrue(app.buttons["15 minutes"].isSelected, "the running timer isn't marked")
        snapshot("6b Sleep Timer")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()
        app.buttons["speed"].tap()
        XCTAssertTrue(app.switches.firstMatch.waitForExistence(timeout: 5))
        snapshot("7 Speed")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()

        // The show name opens the show page in the Shows tab.
        let showName = app.buttons["nowPlayingShow"]
        XCTAssertTrue(showName.waitForExistence(timeout: 5))
        showName.tap()
        XCTAssertTrue(app.navigationBars.buttons["Shows"].waitForExistence(timeout: 5), "the show page didn't open")
        XCTAssertTrue(app.tabBars.buttons["Shows"].isSelected)
    }

    /// Inbox triage. `-fastClock` makes one second pass as one day.
    @MainActor
    func testInbox() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-fastClock", "-hasSeenOnboarding", "YES"]
        app.launch()

        // Subscribing puts the newest episode in the Inbox.
        XCTAssertTrue(app.buttons["Find Shows"].waitForExistence(timeout: 5))
        app.buttons["Find Shows"].tap()
        subscribe(to: feed)
        XCTAssertTrue(app.buttons["Planet Money, NPR"].waitForExistence(timeout: 30))
        app.tabBars.buttons["Queue"].tap()
        let newRow = app.buttons["Inbox · 1 new"]
        XCTAssertTrue(newRow.waitForExistence(timeout: 5))
        snapshot("8 New Row")
        newRow.tap()
        XCTAssertTrue(app.buttons["inboxCard"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Also new · 1"].exists, "one episode needs no Also new heading")
        snapshot("9 Inbox")
        // Show in the card's line opens the episode's show page.
        let item = app.buttons["inboxCard"]
        item.tap()
        app.buttons["Show"].tap()
        XCTAssertTrue(app.buttons["newEpisodesRow"].waitForExistence(timeout: 5), "Show didn't open the show page")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        // The line under the list opens Settings at the Inbox section.
        app.buttons["inboxExpiryLine"].tap()
        let sevenDays = app.buttons["7d"]
        XCTAssertTrue(sevenDays.waitForExistence(timeout: 5))
        snapshot("9b Settings")
        sevenDays.tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // After more than 7 days, a refresh expires it.
        sleep(8)
        let list = app.collectionViews.firstMatch
        list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            .press(forDuration: 0, thenDragTo: list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)))
        // Cassy sums up the refresh. Her toast lasts 5 seconds, so check it first.
        let toast = app.buttons["cassyToast"]
        XCTAssertTrue(toast.waitForExistence(timeout: 30))
        XCTAssertTrue(toast.label.contains("I removed 1 old one from your Inbox."), toast.label)
        snapshot("10a Refresh Summary")
        XCTAssertTrue(newRow.waitForNonExistence(timeout: 5))

        // The show page says why it left, with no Undo.
        app.buttons["Find Shows"].tap()
        app.buttons["Planet Money, NPR"].tap()
        XCTAssertTrue(app.staticTexts["Removed after 7 days"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Undo"].exists)
        snapshot("10 Expired")

        // Where new episodes go is a menu in its row; the Inbox period has its own row, for Inbox shows only.
        let newEpisodes = app.buttons["newEpisodesRow"]
        let removedAfter = app.buttons["removedAfterRow"]
        XCTAssertTrue(removedAfter.waitForExistence(timeout: 5))
        removedAfter.tap()
        choose("3 days")
        XCTAssertTrue(removedAfter.waitForValue("3 days"))
        removedAfter.tap()
        choose("My default (7 days)")
        XCTAssertTrue(removedAfter.waitForValue("7 days"), "My default didn't follow the 7-day default set above")
        newEpisodes.tap()
        snapshot("11 New Episodes Menu")
        choose("Play next")
        XCTAssertTrue(newEpisodes.waitForValue("Play next"))
        XCTAssertTrue(removedAfter.waitForNonExistence(timeout: 5), "the Inbox period stayed for Play next")
        snapshot("11a Show Page")
    }

    /// Rule cards. A threshold of one makes a single expiry raise the Ignored card.
    @MainActor
    func testRuleCard() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-fastClock", "-ruleThresholdOne", "-hasSeenOnboarding", "YES"]
        app.launch()

        XCTAssertTrue(app.buttons["Find Shows"].waitForExistence(timeout: 5))
        app.buttons["Find Shows"].tap()
        subscribe(to: feed)
        XCTAssertTrue(app.buttons["Planet Money, NPR"].waitForExistence(timeout: 30))
        app.tabBars.buttons["Queue"].tap()
        XCTAssertTrue(app.buttons["Inbox · 1 new"].waitForExistence(timeout: 5))

        // The newest episode expires after the 14-day default, which raises the card in its place.
        sleep(15)
        let list = app.collectionViews.firstMatch
        list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            .press(forDuration: 0, thenDragTo: list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)))
        sleep(3)
        app.buttons["Inbox · 1 new"].tap()
        XCTAssertTrue(app.staticTexts["Skip new Planet Money episodes?"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["More options"].exists)
        XCTAssertTrue(app.buttons["Dismiss"].exists)
        snapshot("12 Rule Card")

        // Skip sets the level, so the card goes and the show page has no expiry setting.
        app.buttons["Skip them"].tap()
        XCTAssertTrue(app.staticTexts["Inbox zero!"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Shows"].tap()
        app.buttons["Planet Money, NPR"].tap()
        let newEpisodes = app.buttons["newEpisodesRow"]
        XCTAssertTrue(newEpisodes.waitForExistence(timeout: 5))
        XCTAssertTrue(newEpisodes.waitForValue("Skip"))
    }

    /// Onboarding on first launch: search, star a show, and its newest episode is queued.
    @MainActor
    func testOnboarding() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "NO"]
        app.launch()

        // One welcome screen, then Find Shows.
        let start = app.buttons["Let's add some shows"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Hi, I'm Cassy!"].exists)
        snapshot("12 Welcome")
        start.tap()
        XCTAssertTrue(app.navigationBars["Find Shows"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitForTopShows())
        XCTAssertTrue(app.staticTexts["Let's add some shows!"].exists)
        XCTAssertTrue(app.buttons["Skip"].exists)
        snapshot("13 Onboarding")
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("planet money")
        XCTAssertTrue(app.staticTexts["Results"].waitForExistence(timeout: 10))
        let star = app.buttons.matching(identifier: "starButton").firstMatch
        XCTAssertTrue(star.waitForExistence(timeout: 15))
        star.tap()
        XCTAssertTrue(app.buttons["Unstar"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["Nice pick!"].waitForExistence(timeout: 5))
        snapshot("14 Starred")
        app.buttons["Close"].tap()
        app.buttons["Done"].tap()

        // A starred show's episodes carry a star, and the show sits under Starred.
        let queued = app.buttons.matching(identifier: "queueItem").firstMatch
        XCTAssertTrue(queued.waitForExistence(timeout: 10))
        XCTAssertTrue(queued.label.hasPrefix("Starred"), queued.label)
        snapshot("14a Starred Queue")
        app.tabBars.buttons["Shows"].tap()
        XCTAssertTrue(app.buttons["Planet Money, NPR"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Starred"].exists, "no Starred section")
        XCTAssertFalse(app.staticTexts["More Shows"].exists, "an empty More Shows section")
        snapshot("14b Starred Section")

        // OPML export sits in the Add menu.
        app.navigationBars["Shows"].buttons["Add"].tap()
        XCTAssertTrue(app.buttons["Export OPML File"].waitForExistence(timeout: 5))
    }

    /// Capture: bookmark while playing, add a note from the toast, find it, and export it.
    @MainActor
    func testCapture() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()

        app.tabBars.buttons["Shows"].tap()
        subscribe(to: feed)
        let show = app.buttons["Planet Money, NPR"]
        XCTAssertTrue(show.waitForExistence(timeout: 30))
        show.tap()
        let episode = app.buttons.matching(identifier: "episode").firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 10))
        episode.playFromRow()
        XCTAssertTrue(app.buttons["miniPlayer"].waitForExistence(timeout: 15))

        // One tap in Now Playing bookmarks without pausing; Add Note on the toast opens it in Bookmarks, ready to type.
        app.buttons["miniPlayer"].tap()
        let bookmark = app.buttons["Bookmark"].firstMatch
        XCTAssertTrue(bookmark.waitForExistence(timeout: 5))
        bookmark.tap()
        let toast = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Bookmarked at'")).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Pause"].firstMatch.exists)
        snapshot("15 Bookmark Toast")
        app.buttons["Add Note"].firstMatch.tap()
        let noteField = app.descendants(matching: .any)["bookmarkNoteField"]
        XCTAssertTrue(noteField.waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "no keyboard in the note")
        XCTAssertFalse(app.buttons["nowPlayingShow"].exists, "Now Playing stayed open")
        app.typeText("great point\n")

        // The Bookmarks tab lists it with a play button, and it exports alone or with all.
        let saved = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == 'great point'"), object: noteField)], timeout: 5)
        XCTAssertEqual(saved, .completed, "note is \(noteField.value ?? "nil")")
        let play = app.buttons["bookmarkPlay"]
        XCTAssertTrue(play.exists && play.label.hasPrefix("Play from"), play.debugDescription)
        XCTAssertTrue(app.buttons["Export"].exists)
        XCTAssertTrue(app.buttons["Export All"].exists)
        snapshot("16 Bookmarks")

        // Edit the note in place.
        noteField.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        noteField.typeText(" again")
        noteField.typeText("\n")
        let edited = NSPredicate(format: "value == 'great point again'")
        let result = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: edited, object: noteField)], timeout: 5)
        XCTAssertEqual(result, .completed, "note is \(noteField.value ?? "nil")")

        // Search covers notes.
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("GREAT")
        XCTAssertTrue(noteField.waitForExistence(timeout: 5))
        search.typeText("zzz")
        XCTAssertTrue(noteField.waitForNonExistence(timeout: 5))

        // Tapping the rest of the toast opens Bookmarks without the keyboard.
        app.buttons["Close"].firstMatch.tap()
        app.tabBars.buttons["Queue"].tap()
        // The mini player has no bookmark button, so bookmark from Now Playing again.
        XCTAssertFalse(app.buttons["Bookmark"].exists, "a bookmark button on the mini player")
        app.buttons["miniPlayer"].tap()
        app.buttons["Bookmark"].firstMatch.tap()
        let text = app.buttons["bookmarkToast"].firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        text.tap()
        XCTAssertTrue(noteField.waitForExistence(timeout: 5), "the toast didn't open Bookmarks")
        XCTAssertFalse(app.keyboards.firstMatch.exists, "the keyboard came up without Add Note")
    }

    /// ATP embeds chapters in its MP3s: the pill appears, the list shows time left, and a chapter jumps.
    @MainActor
    func testChapters() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()

        app.tabBars.buttons["Shows"].tap()
        subscribe(to: "https://atp.fm/rss")
        let show = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Accidental Tech Podcast'")).firstMatch
        XCTAssertTrue(show.waitForExistence(timeout: 30))
        show.tap()
        let episode = app.buttons.matching(identifier: "episode").firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 10))
        episode.playFromRow()
        let miniPlayer = app.buttons["miniPlayer"]
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 15))
        miniPlayer.tap()

        let pill = app.buttons["chapterPill"]
        XCTAssertTrue(pill.waitForExistence(timeout: 30), "no chapter pill")
        XCTAssertTrue(pill.label.hasPrefix("Chapter 1 of "), pill.label)
        snapshot("17 Chapter Pill")
        pill.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ENDSWITH 'min left'")).firstMatch.waitForExistence(timeout: 5))
        snapshot("18 Chapters")

        // Jump to the third chapter: the elapsed time moves to its start.
        let rows = app.buttons.matching(NSPredicate(format: "label CONTAINS ', starts at '"))
        let third = rows.element(boundBy: 2)
        let start = try XCTUnwrap(third.label.components(separatedBy: ", starts at ").last)
        third.tap()
        let elapsed = app.staticTexts["elapsed"]
        XCTAssertTrue(elapsed.waitForExistence(timeout: 5))
        let atStart = NSPredicate(format: "label == %@ OR label BEGINSWITH %@", start, String(start.dropLast()))
        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: atStart, object: elapsed)], timeout: 5), .completed,
                       "elapsed is \(elapsed.label), chapter starts at \(start)")
        XCTAssertTrue(pill.label.hasPrefix("Chapter 3 of "), pill.label)
        sleep(3)
        snapshot("19 Chapter Pill After Jump")
        pill.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ENDSWITH 'min left'")).firstMatch.waitForExistence(timeout: 5))
        snapshot("20 Chapters After Jump")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()

        // The sleep timer can stop at the end of this chapter.
        let timer = app.buttons["Sleep timer"]
        timer.tap()
        let thisChapter = app.buttons["This chapter"]
        XCTAssertTrue(thisChapter.waitForExistence(timeout: 5), "no This chapter for an episode with chapters")
        snapshot("20b Sleep Timer With Chapters")
        thisChapter.tap()
        let untilChapterEnd = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == 'Pauses at the end of the chapter'"), object: timer)
        XCTAssertEqual(XCTWaiter().wait(for: [untilChapterEnd], timeout: 5), .completed, "sleep timer says \(timer.value ?? "nil")")
    }

    /// Now Playing's share menu offers Share Episode and Share Clip, and Share Episode opens the share sheet.
    /// The show page offers Share Show, and Share in a row's action line.
    @MainActor
    func testShareMenu() throws {
        try openATPNowPlaying()
        app.buttons["nowPlayingShare"].tap()
        let shareEpisode = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Share Episode'")).firstMatch
        XCTAssertTrue(shareEpisode.waitForExistence(timeout: 5), "no Share Episode")
        XCTAssertTrue(app.buttons["Share Clip"].exists, "no Share Clip")
        snapshot("25 Share Menu")
        shareEpisode.tap()
        let sheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 10), "Share Episode didn't open the share sheet")
        snapshot("26 Share Episode Sheet")
        // Tapping above the sheet closes it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5))

        app.swipeDown(velocity: .fast)
        XCTAssertTrue(app.navigationBars.buttons["Share Show"].waitForExistence(timeout: 5), "no Share Show")
        app.buttons.matching(identifier: "episode").firstMatch.tap()
        XCTAssertTrue(app.buttons["Share"].waitForExistence(timeout: 5), "no Share in the row's line")
    }

    /// The clip editor opens around now, an edge drag changes the length, and the length stops at 60 s.
    @MainActor
    func testClipEditor() throws {
        try openATPNowPlaying()
        // Move to the middle of the episode and pause right away. The drag must land even if it never reports its end.
        let elapsed = app.staticTexts["elapsed"]
        app.sliders.firstMatch.adjust(toNormalizedSliderPosition: 0.3)
        app.buttons["pause.circle.fill"].tap()
        let now = try XCTUnwrap(seconds(elapsed.label))
        XCTAssertGreaterThan(now, 600)
        app.buttons["nowPlayingShare"].tap()
        app.buttons["Share Clip"].tap()

        let end = app.otherElements["clipEnd"]
        XCTAssertTrue(end.waitForExistence(timeout: 20), "no bars")
        let nowLabel = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'now '")).firstMatch
        XCTAssertEqual(try XCTUnwrap(seconds(String(nowLabel.label.dropFirst(4)))), now, accuracy: 1, nowLabel.label)
        let times = app.staticTexts["clipTimes"]
        let (start, finish, length) = try clipTimes(times.label)
        XCTAssertEqual(start, now - 15, accuracy: 1.5, times.label)
        XCTAssertEqual(finish, now + 15, accuracy: 1.5, times.label)
        XCTAssertTrue((29...31).contains(length), times.label)
        // The label shows tenths, so compare to the second instead of matching rounded text.
        let endValue = try XCTUnwrap(end.value as? String)
        XCTAssertTrue(endValue.hasPrefix("Ends at "), endValue)
        XCTAssertEqual(try XCTUnwrap(seconds(String(endValue.dropFirst(8)))), finish, accuracy: 1, endValue)
        snapshot("27 Clip Editor")

        // Preview plays the fetched audio until stopped.
        let preview = app.buttons["clipPreview"]
        preview.tap()
        XCTAssertTrue(app.buttons["Stop"].waitForExistence(timeout: 3), "Preview didn't play")
        preview.tap()
        XCTAssertTrue(app.buttons["Preview"].waitForExistence(timeout: 3))

        app.buttons["clipShare"].tap()
        let sheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 30), "Share didn't open the share sheet")
        snapshot("28 Clip Share Sheet")
        app.buttons["Close"].tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5))

        let grip = end.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        grip.press(forDuration: 0.2, thenDragTo: grip.withOffset(CGVector(dx: 90, dy: 0)))
        let longer = try clipTimes(times.label).length
        XCTAssertGreaterThan(longer, length + 3, times.label)
        let movedGrip = end.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        movedGrip.press(forDuration: 0.2, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0)).withOffset(CGVector(dx: 0, dy: end.frame.midY)))
        XCTAssertEqual(try clipTimes(times.label).length, 60, times.label)
        snapshot("29 Clip At Sixty")
    }

    /// Subscribes to ATP, plays its latest episode, and opens Now Playing.
    @MainActor
    private func openATPNowPlaying() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()
        app.tabBars.buttons["Shows"].tap()
        subscribe(to: "https://atp.fm/rss")
        let show = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Accidental Tech Podcast'")).firstMatch
        XCTAssertTrue(show.waitForExistence(timeout: 30))
        show.tap()
        let episode = app.buttons.matching(identifier: "episode").firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 10))
        episode.playFromRow()
        let miniPlayer = app.buttons["miniPlayer"]
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 15))
        miniPlayer.tap()
        let share = app.buttons["nowPlayingShare"]
        XCTAssertTrue(share.waitForExistence(timeout: 10), "no share button")
        // Wait for the duration, which the editor needs.
        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != '0:00'"),
                                                                        object: app.staticTexts["elapsed"])], timeout: 30), .completed)
    }

    /// "12:04.4 – 12:33.8 · 0:29" as start, end and whole seconds of length.
    private func clipTimes(_ label: String) throws -> (start: TimeInterval, end: TimeInterval, length: Int) {
        let parts = label.components(separatedBy: CharacterSet(charactersIn: "–·")).map { $0.trimmingCharacters(in: .whitespaces) }
        XCTAssertEqual(parts.count, 3, label)
        return (try XCTUnwrap(seconds(parts[0])), try XCTUnwrap(seconds(parts[1])), Int(try XCTUnwrap(seconds(parts[2]))))
    }

    /// Seconds in "1:02:03", "12:04" or "12:04.4".
    private func seconds(_ clock: String) -> TimeInterval? {
        let fields = clock.split(separator: ":").map { Double($0) }
        guard !fields.isEmpty, !fields.contains(nil) else { return nil }
        return fields.compactMap(\.self).reduce(0) { $0 * 60 + $1 }
    }

    /// A shared audio file arrives in the Queue, plays, and lives on the Shared with Casterr page.
    @MainActor
    func testSharedFile() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        let fixture = try XCTUnwrap(Bundle(for: Self.self).path(forResource: "shared-interview", ofType: "m4a"))
        app.launchEnvironment = ["SHARED_FIXTURE": fixture, "SHARED_FIXTURE_TITLE": "Interview with Dana"]
        app.launch()

        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Interview with Dana'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "shared file isn't in the Queue")
        snapshot("21 Shared In Queue")
        app.buttons["upNextPlay"].tap()
        let miniPlayer = app.buttons["miniPlayer"]
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 10))
        miniPlayer.tap()
        let elapsed = app.staticTexts["elapsed"]
        XCTAssertTrue(elapsed.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["nowPlayingShare"].exists, "a shared file offers sharing")
        let advanced = NSPredicate(format: "label != '0:00'")
        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: advanced, object: elapsed)], timeout: 10), .completed,
                       "shared file didn't play")
        snapshot("22 Shared Now Playing")

        // It lives on the Shared with Casterr page, where Delete removes it everywhere.
        app.swipeDown(velocity: .fast)
        app.tabBars.buttons["Shows"].tap()
        let sharedShow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Shared with Casterr'")).firstMatch
        XCTAssertTrue(sharedShow.waitForExistence(timeout: 5), "no Shared with Casterr in the grid")
        sharedShow.tap()
        let episode = app.buttons.matching(identifier: "episode").firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["followShow"].exists, "the built-in show offers Follow")
        XCTAssertFalse(app.navigationBars.buttons["Share Show"].exists, "the built-in show offers Share Show")
        episode.tap()
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Share"].exists, "a shared file offers Share")
        episode.tap()
        XCTAssertTrue(app.buttons["Delete"].waitForNonExistence(timeout: 5))
        snapshot("23 Shared With Casterr")
        episode.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(episode.waitForNonExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Queue"].tap()
        XCTAssertTrue(app.staticTexts["Silence. Lovely, but let's fix that."].waitForExistence(timeout: 5))
    }

    /// A shared Apple Podcasts episode plays next; its show's page offers Follow until you do.
    @MainActor
    func testSharedLinkAndSubscribe() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launchEnvironment = ["SHARED_LINK": "https://podcasts.apple.com/us/podcast/two-hot-streaks/id617416468?i=1000801592580"]
        app.launch()

        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Two Hot Streaks'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 30), "shared episode isn't in the Queue")
        app.buttons["upNextPlay"].tap()
        app.buttons["miniPlayer"].tap()
        let showName = app.buttons["nowPlayingShow"]
        XCTAssertTrue(showName.waitForExistence(timeout: 10))
        showName.tap()

        let follow = app.buttons["followShow"]
        XCTAssertTrue(follow.waitForExistence(timeout: 10), "no Follow on an unfollowed show")
        XCTAssertEqual(follow.label, "Follow")
        XCTAssertTrue(app.buttons["starShow"].exists)
        snapshot("24 Unfollowed Show")
        follow.tap()
        // The settings show while the feed still downloads.
        XCTAssertTrue(app.buttons["newEpisodesRow"].exists, "the settings waited for the follow")
        XCTAssertEqual(app.buttons["newEpisodesRow"].value as? String, "Inbox")
        XCTAssertTrue(app.buttons["removedAfterRow"].exists)
        XCTAssertEqual(follow.label, "Following")
    }

    /// The first follow with + shows a one-time tip on that show's star.
    @MainActor
    func testStarTip() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "NO", "-hasSeenTip.star", "NO"]
        app.launch()

        let start = app.buttons["Let's add some shows"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        XCTAssertTrue(waitForTopShows())
        let follow = app.buttons.matching(identifier: "subscribeButton").firstMatch
        XCTAssertTrue(follow.waitForExistence(timeout: 5))
        follow.tap()
        let tip = app.staticTexts["Never miss this one? Star it and I'll queue its new episodes."]
        XCTAssertTrue(tip.waitForExistence(timeout: 30))
        snapshot("13b Star Tip")

        // The ✕ closes it.
        app.buttons["Dismiss tip"].tap()
        XCTAssertTrue(tip.waitForNonExistence(timeout: 5))
    }

    /// After onboarding: Find Shows in the + menu, and a Shows search that covers only your shows.
    @MainActor
    func testFindMoreShows() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()

        app.tabBars.buttons["Shows"].tap()
        subscribe(to: feed)
        XCTAssertTrue(app.buttons["Planet Money, NPR"].waitForExistence(timeout: 30))

        app.navigationBars["Shows"].buttons["Add"].tap()
        app.buttons["Find Shows"].tap()
        XCTAssertTrue(app.navigationBars["Find Shows"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitForTopShows())
        snapshot("25 Find Shows Sheet")
        // A row opens the show's page without following it. The directory's name shows at once,
        // while the episodes are still placeholders.
        let row = app.buttons.matching(identifier: "directoryShow").firstMatch
        let title = String(row.label.split(separator: ",").first ?? "")
        row.tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 2), "the directory's name \(title) didn't show at once")
        snapshot("25a Show Loading")
        XCTAssertTrue(app.buttons.matching(identifier: "episode").firstMatch.waitForExistence(timeout: 30), "no episodes on a Find Shows page")
        XCTAssertEqual(app.buttons["followShow"].label, "Follow")
        snapshot("25b Show From Find Shows")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Cassy cheers for a star given during this visit, and stops when it's taken back.
        let invite = app.staticTexts["Let's add some shows!"]
        let cheer = app.staticTexts["Nice pick!"]
        XCTAssertTrue(invite.waitForExistence(timeout: 5))
        let star = app.buttons.matching(identifier: "starButton").firstMatch
        star.tap()
        XCTAssertTrue(cheer.waitForExistence(timeout: 30), "no cheer for a star")
        star.tap()
        XCTAssertTrue(invite.waitForExistence(timeout: 30), "still cheering after unstarring")
        star.tap()
        XCTAssertTrue(cheer.waitForExistence(timeout: 30))
        app.navigationBars["Find Shows"].buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Find Shows"].waitForNonExistence(timeout: 5))

        // On the next visit, a star from before doesn't count.
        app.navigationBars["Shows"].buttons["Add"].tap()
        app.buttons["Find Shows"].tap()
        XCTAssertTrue(waitForTopShows())
        XCTAssertTrue(invite.waitForExistence(timeout: 5), "a star from an earlier visit made Cassy cheer")
        XCTAssertFalse(cheer.exists)
        app.navigationBars["Find Shows"].buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Find Shows"].waitForNonExistence(timeout: 5))

        let search = app.searchFields["Search shows"]
        search.tap()
        search.typeText("planet")
        XCTAssertTrue(app.buttons["Planet Money, NPR"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons.matching(identifier: "starButton").firstMatch.waitForExistence(timeout: 3), "directory shows in the Shows search")
        snapshot("26 Search Your Shows")
        search.typeText("zzz")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'No Results'")).firstMatch.waitForExistence(timeout: 5))
    }

    /// Clear Cache in Settings empties the kept art and popular lists.
    @MainActor
    func testClearCache() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()
        // Find Shows keeps both charts and their art.
        app.tabBars.buttons["Shows"].tap()
        XCTAssertTrue(waitForTopShows())

        app.tabBars.buttons["Queue"].tap()
        app.navigationBars.buttons["Settings"].tap()
        let size = app.descendants(matching: .any)["cacheSize"]
        for _ in 0..<4 where !size.exists { app.swipeUp() }
        XCTAssertTrue(size.waitForExistence(timeout: 5))
        let shown = { "\(size.label) \(size.value as? String ?? "")" }
        XCTAssertTrue(app.descendants(matching: .any)["downloadsSize"].exists, "no downloads row in Storage")
        let before = shown()
        app.buttons["Clear Cache"].tap()
        XCTAssertTrue(app.buttons["Cleared"].waitForExistence(timeout: 1), "Clear Cache didn't confirm")
        // The size drops as iOS empties its download cache in the background.
        for _ in 0..<5 where shown() == before { _ = size.waitForNonExistence(timeout: 1) }
        XCTAssertNotEqual(shown(), before)
        snapshot("28 Clear Cache")
    }

    /// Follow, Star, the New episodes row and Settings show a tap at once, before the save lands.
    /// Each check reads the state right after the tap, with no waiting.
    @MainActor
    func testInstantControls() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenTip.star", "YES", "-hasSeenOnboarding", "NO"]
        app.launch()
        // Onboarding's Find Shows stays open after a follow, unlike the Shows tab, which then shows the grid.
        app.buttons["Let's add some shows"].tap()
        XCTAssertTrue(waitForTopShows())

        // Find Shows: Follow shows Unfollow while the feed still downloads.
        let follow = app.buttons.matching(identifier: "subscribeButton").firstMatch
        follow.tap()
        XCTAssertEqual(follow.label, "Unfollow", "Follow waited for the feed")
        XCTAssertTrue(follow.isEnabled, "the row's buttons are disabled while saving")
        XCTAssertTrue(follow.wait(for: \.label, toEqual: "Unfollow", timeout: 40))
        let star = app.buttons.matching(identifier: "starButton").firstMatch
        star.tap()
        XCTAssertEqual(star.label, "Unstar", "Star waited for the save")

        // The show page: Star flips at once, and so does the New episodes row.
        app.buttons.matching(identifier: "directoryShow").firstMatch.tap()
        let starShow = app.buttons["starShow"]
        XCTAssertTrue(starShow.waitForExistence(timeout: 30))
        XCTAssertTrue(starShow.wait(for: \.label, toEqual: "Starred", timeout: 10))
        starShow.tap()
        XCTAssertEqual(starShow.label, "Star", "Star on the show page waited for the save")
        let newEpisodes = app.buttons["newEpisodesRow"]
        XCTAssertTrue(newEpisodes.waitForExistence(timeout: 10))
        newEpisodes.tap()
        choose("Skip")
        XCTAssertEqual(newEpisodes.value as? String, "Skip", "the row waited for the save")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Done"].tap()

        // Settings: Keep downloaded shows the new choice at once.
        app.tabBars.buttons["Queue"].tap()
        app.navigationBars.buttons["Settings"].tap()
        let one = app.buttons["1"]
        XCTAssertTrue(one.waitForExistence(timeout: 5))
        one.tap()
        XCTAssertTrue(one.isSelected, "Keep downloaded waited for the save")
    }

    /// A long show draws its newest 30 episodes, then Show older episodes, which adds the next 30 below.
    @MainActor
    func testShowOlderEpisodes() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()
        app.tabBars.buttons["Shows"].tap()
        subscribe(to: feed)
        let tile = app.buttons["Planet Money, NPR"]
        XCTAssertTrue(tile.waitForExistence(timeout: 30))
        tile.tap()
        XCTAssertTrue(app.buttons.matching(identifier: "episode").firstMatch.waitForExistence(timeout: 30))
        // The long description folds to two lines with Show more, and a tap anywhere on it opens it.
        let description = app.buttons["showDescription"]
        XCTAssertTrue(description.waitForExistence(timeout: 5), "no Show more on a long description")
        XCTAssertTrue(description.label.contains("Show more"), description.label)
        description.tap()
        expectation(for: NSPredicate(format: "label CONTAINS 'Show less'"), evaluatedWith: description)
        waitForExpectations(timeout: 5)
        description.tap()
        let older = app.buttons["showOlder"]
        for _ in 0..<15 where !older.isHittable { app.swipeUp() }
        XCTAssertTrue(older.isHittable, "no Show older episodes after the first 30")
        snapshot("30 Show Older Episodes")
        older.tap()
        // The next 30 slide in above the row, so it's pushed off screen until the list scrolls again.
        XCTAssertTrue(older.waitForNonExistence(timeout: 2) || !older.isHittable, "Show older episodes added nothing")
        for _ in 0..<15 where !older.isHittable { app.swipeUp() }
        XCTAssertTrue(older.isHittable, "no Show older episodes after 60")
    }

    /// Headphone and car buttons: the footer says what each press does and follows a change.
    @MainActor
    func testHeadphoneButtons() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()
        app.navigationBars.buttons["Settings"].tap()
        let footer = app.staticTexts["buttonsFooter"]
        for _ in 0..<6 where !footer.isHittable { app.swipeUp() }
        XCTAssertTrue(footer.waitForExistence(timeout: 5), "no Headphone and car buttons footer")
        XCTAssertTrue(footer.label.hasPrefix("Double press bookmarks, with a chime. Triple press skips back 15."), footer.label)
        snapshot("29 Headphone Buttons")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Triple press'")).firstMatch.tap()
        let skipForward = app.buttons["Skip forward 30"]
        XCTAssertTrue(skipForward.waitForExistence(timeout: 5), "the Triple press menu didn't open")
        skipForward.tap()
        let changed = NSPredicate(format: "label CONTAINS 'Triple press skips forward 30.'")
        expectation(for: changed, evaluatedWith: footer)
        waitForExpectations(timeout: 5)
    }

    /// Outside the United States, the heading switches the chart to the United States, and the choice is kept.
    /// After an update, Cassy offers What's New; Settings ends with the version, which opens it too.
    @MainActor
    func testWhatsNew() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES",
                               "-lastSeenVersion", "0.1"]
        app.launch()
        let toast = app.buttons["cassyToast"]
        XCTAssertTrue(toast.waitForExistence(timeout: 5), "no update toast")
        XCTAssertTrue(toast.label.contains("I learned some new tricks."), toast.label)
        toast.tap()
        XCTAssertTrue(app.navigationBars["What's New"].waitForExistence(timeout: 3))
        // The oldest unseen version is at the bottom, below the screen once the list is long.
        let oldest = app.staticTexts.matching(NSPredicate(format: "label ==[c] 'Version 0.2'")).firstMatch
        for _ in 0..<6 where !oldest.exists { app.swipeUp() }
        XCTAssertTrue(oldest.exists, "no 0.2 section")
        XCTAssertFalse(app.staticTexts["VERSION 0.1"].exists || app.staticTexts["Version 0.1"].exists, "lists 0.1, already seen")
        snapshot("29 Whats New")
        app.navigationBars["What's New"].buttons["Done"].tap()

        app.navigationBars.buttons["Settings"].tap()
        let version = app.buttons["version"]
        app.swipeUp(); app.swipeUp()
        XCTAssertTrue(version.waitForExistence(timeout: 3), "no version in Settings")
        let current = Bundle(for: Self.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        XCTAssertTrue(version.label.contains("Version \(current)"), "\(version.label) is not \(current)")
        version.tap()
        XCTAssertTrue(app.navigationBars["What's New"].waitForExistence(timeout: 3))
        let first = { [app] in app!.staticTexts["VERSION 0.1"].exists || app!.staticTexts["Version 0.1"].exists }
        for _ in 0..<4 where !first() { app.swipeUp() }
        XCTAssertTrue(first(), "Settings should list every version")
    }

    @MainActor
    func testChartCountry() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES", "-AppleLocale", "en_IL"]
        app.launch()
        app.tabBars.buttons["Shows"].tap()
        XCTAssertTrue(waitForTopShows())

        // Start from the region, whatever an earlier run left.
        pickChart("Israel")
        XCTAssertTrue(app.buttons["chartCountry"].label.hasPrefix("Popular now · Israel"))
        pickChart("United States")
        XCTAssertTrue(waitForTopShows())
        XCTAssertTrue(app.buttons["chartCountry"].label.hasPrefix("Popular now · United States"))
        snapshot("27 Chart Country")

        app.terminate()
        app.launch()
        app.tabBars.buttons["Shows"].tap()
        XCTAssertTrue(waitForTopShows())
        XCTAssertTrue(app.buttons["chartCountry"].label.hasPrefix("Popular now · United States"), "the choice wasn't kept")

        // Both charts are saved now, so switching shows the other one at once, with no loading.
        pickChart("Israel")
        XCTAssertFalse(app.staticTexts["Flipping through the shelves…"].exists, "switching to a saved chart showed loading")
        XCTAssertTrue(app.buttons.matching(identifier: "starButton").firstMatch.waitForExistence(timeout: 1))
    }

    @MainActor
    private func pickChart(_ country: String) {
        let menu = app.buttons["chartCountry"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        let item = app.buttons[country]
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.tap()
        XCTAssertTrue(app.buttons["chartCountry"].waitForExistence(timeout: 5))
    }

    /// Waits for Apple's top shows. Its chart fails now and then, so this taps Try Again a few times.
    @MainActor
    private func waitForTopShows() -> Bool {
        for _ in 0..<4 {
            // Plain text, or a menu outside the United States.
            let heading = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Popular now'")).firstMatch
            if heading.waitForExistence(timeout: 25) { return true }
            let retry = app.buttons["Try Again"]
            guard retry.exists else { return false }
            retry.tap()
        }
        return false
    }

    /// The newest episode is on a card, and the rest wait under Also new. Swiping the card queues or removes it.
    @MainActor
    func testInboxCard() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()

        app.tabBars.buttons["Shows"].tap()
        for address in [feed, "https://feeds.npr.org/510325/podcast.xml", "https://feeds.npr.org/510318/podcast.xml"] {
            subscribe(to: address)
            XCTAssertTrue(app.navigationBars["Add Show"].waitForNonExistence(timeout: 30))
        }
        app.tabBars.buttons["Queue"].tap()
        let newRow = app.buttons["Inbox · 3 new"]
        XCTAssertTrue(newRow.waitForExistence(timeout: 30))
        newRow.tap()
        let card = app.buttons["inboxCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Also new · 2"].exists)
        snapshot("9c Inbox Card")

        // A tap opens the line of actions, with Play first.
        card.tap()
        XCTAssertTrue(app.buttons["rowPlay"].waitForExistence(timeout: 5))
        card.tap()

        // Right queues: the next episode takes the card.
        let first = card.label
        card.swipeRight()
        XCTAssertTrue(app.staticTexts["Also new · 1"].waitForExistence(timeout: 5))
        XCTAssertNotEqual(card.label, first)
        // Left removes.
        card.swipeLeft()
        XCTAssertTrue(app.staticTexts["Also new · 1"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(card.exists, "the last episode should be on the card")
        snapshot("9d Inbox Card Last")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Inbox · 1 new"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "queueItem").count, 1, "the swiped-right episode should be queued")
    }

    /// The first Inbox visit teaches the swipes with a one-time tip on the card.
    @MainActor
    func testInboxSwipeTip() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-fastClock", "-hasSeenOnboarding", "YES", "-hasSeenTip.inboxCardSwipe", "NO"]
        app.launch()

        app.tabBars.buttons["Shows"].tap()
        subscribe(to: feed)
        XCTAssertTrue(app.buttons["Planet Money, NPR"].waitForExistence(timeout: 30))
        app.tabBars.buttons["Queue"].tap()
        app.buttons["Inbox · 1 new"].tap()
        let tip = app.staticTexts["Swipe right to queue an episode, or left to remove it."]
        XCTAssertTrue(tip.waitForExistence(timeout: 10))
        snapshot("8b Inbox Tip")
        app.buttons["Dismiss tip"].tap()
        XCTAssertTrue(tip.waitForNonExistence(timeout: 5))

        // In its last 3 days, a row quietly says when it leaves (one second passes as one day).
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(10)
        app.buttons["Inbox · 1 new"].tap()
        let countdown = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'removed'")).firstMatch
        XCTAssertTrue(countdown.waitForExistence(timeout: 10))
        snapshot("8c Countdown")

        // Swiping left removes it. The launch argument shows the tip on every visit, so close it first.
        if app.buttons["Dismiss tip"].exists { app.buttons["Dismiss tip"].tap() }
        app.buttons["inboxCard"].swipeLeft()
        XCTAssertTrue(app.staticTexts["Inbox zero!"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func subscribe(to address: String) {
        app.navigationBars["Shows"].buttons["Add"].tap()
        app.buttons["Add by Feed Address"].tap()
        let field = app.textFields["feedAddress"]
        field.tap()
        field.typeText(address)
        app.navigationBars["Add Show"].buttons["Follow"].tap()
    }

    @MainActor
    /// Taps the open menu's choice named `title`, with or without its explanation after it.
    private func choose(_ title: String) {
        let predicate = NSPredicate(format: "label == %@ OR label BEGINSWITH %@", title, title + ", ")
        let choice = app.buttons.matching(predicate).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5), "no \(title) in the menu")
        choice.tap()
    }

    private func snapshot(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

extension XCUIElement {
    /// Waits until the element's accessibility value reads `value`.
    @MainActor
    func waitForValue(_ value: String, timeout: TimeInterval = 5) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Opens an episode row's action line and taps Play.
    @MainActor
    func playFromRow() {
        tap()
        let play = XCUIApplication().buttons["rowPlay"]
        XCTAssertTrue(play.waitForExistence(timeout: 5), "no Play in the row's line")
        play.tap()
    }
}
