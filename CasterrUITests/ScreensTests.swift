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
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()

        // Queue is the home screen; empty state links to shows.
        XCTAssertTrue(app.staticTexts["Silence. Lovely, but let's fix that."].waitForExistence(timeout: 5))
        snapshot("1 Empty Queue")
        app.buttons["Find Shows"].tap()
        XCTAssertTrue(waitForTopShows())

        // Subscribe by RSS URL: error messages, then success.
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

        // Search lists your matching shows first, then more from the directory.
        let search = app.searchFields["Search shows"]
        search.tap()
        search.typeText("planet")
        XCTAssertTrue(app.staticTexts["Your shows"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["More shows"].waitForExistence(timeout: 20))
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
        for index in 0..<3 {
            episodes.element(boundBy: index).swipeRight()
            app.buttons["Add to Queue"].tap()
        }
        XCTAssertTrue(app.staticTexts["Queued"].waitForExistence(timeout: 5))
        episodes.element(boundBy: 2).swipeLeft()
        app.buttons["Mark Played"].tap()
        // Played episodes fold into a row above the list.
        XCTAssertTrue(app.staticTexts["Played"].waitForExistence(timeout: 5))
        snapshot("4 Show Page")

        // Unsubscribe keeps queued episodes.
        app.navigationBars.buttons["More"].tap()
        app.buttons["Unsubscribe"].tap()
        app.buttons.matching(identifier: "Unsubscribe").element(boundBy: 0).tap()
        XCTAssertTrue(waitForTopShows())
        app.tabBars.buttons["Queue"].tap()

        // Queue: two items in the order added; remove the second.
        let queue = app.buttons.matching(identifier: "queueItem")
        XCTAssertTrue(queue.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(queue.count, 2)
        XCTAssertTrue(app.staticTexts["Up next"].exists)
        // Nothing plays yet, so the bar offers the first Queue episode as new, not as continue.
        let upNext = app.buttons["upNextBar"]
        XCTAssertTrue(upNext.waitForExistence(timeout: 5))
        XCTAssertTrue(upNext.label.hasPrefix("Up next"), upNext.label)
        snapshot("5 Queue")

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
        let downloaded = app.images["Downloaded"]
        XCTAssertTrue(downloaded.waitForExistence(timeout: 120))
        snapshot("5b Downloaded")
        app.navigationBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Off"].waitForExistence(timeout: 5))
        app.buttons["Off"].tap()
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
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxSwipe", "YES", "-fastClock", "-hasSeenOnboarding", "YES"]
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
        XCTAssertTrue(app.buttons.matching(identifier: "inboxItem").firstMatch.waitForExistence(timeout: 5))
        snapshot("9 Inbox")
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

        // The show page explains the move and offers Undo.
        app.buttons["Find Shows"].tap()
        app.buttons["Planet Money, NPR"].tap()
        XCTAssertTrue(app.staticTexts["Removed after 7 days"].waitForExistence(timeout: 5))
        snapshot("10 Expired")
        app.buttons["Undo"].tap()
        XCTAssertTrue(app.staticTexts["In Inbox"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Undo"].exists)

        // New-episode settings open in a sheet; the Inbox period applies to Inbox shows only.
        let newEpisodes = app.buttons["newEpisodesRow"]
        newEpisodes.tap()
        let useDefault = app.switches.firstMatch
        XCTAssertTrue(useDefault.waitForExistence(timeout: 5))
        snapshot("11 New Episodes Sheet")
        app.buttons["Play next"].tap()
        XCTAssertTrue(useDefault.waitForNonExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(newEpisodes.waitForExistence(timeout: 5))
        XCTAssertTrue(newEpisodes.label.contains("Play next"), newEpisodes.label)
        snapshot("11a Show Page")

        // Remove from the Inbox.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Queue"].tap()
        XCTAssertTrue(newRow.waitForExistence(timeout: 5))
        newRow.tap()
        let item = app.buttons.matching(identifier: "inboxItem").firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.swipeLeft()
        app.buttons["Remove"].tap()
        XCTAssertTrue(app.staticTexts["Inbox zero!"].waitForExistence(timeout: 5))
    }

    /// Rule cards. A threshold of one makes a single expiry raise the Ignored card.
    @MainActor
    func testRuleCard() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxSwipe", "YES", "-fastClock", "-ruleThresholdOne", "-hasSeenOnboarding", "YES"]
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
        XCTAssertTrue(newEpisodes.label.contains("Skipped"), newEpisodes.label)
    }

    /// Onboarding on first launch: search, star a show, and its newest episode is queued.
    @MainActor
    func testOnboarding() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxSwipe", "YES", "-hasSeenOnboarding", "NO"]
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

        XCTAssertTrue(app.buttons.matching(identifier: "queueItem").firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Shows"].tap()
        XCTAssertTrue(app.buttons["Planet Money, NPR"].waitForExistence(timeout: 5))

        // OPML export sits in the Add menu.
        app.navigationBars["Shows"].buttons["Add"].tap()
        XCTAssertTrue(app.buttons["Export OPML File"].waitForExistence(timeout: 5))
    }

    /// Capture: bookmark while playing, add a note from the toast, find it, and export it.
    @MainActor
    func testCapture() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()

        app.tabBars.buttons["Shows"].tap()
        subscribe(to: feed)
        let show = app.buttons["Planet Money, NPR"]
        XCTAssertTrue(show.waitForExistence(timeout: 30))
        show.tap()
        let episode = app.buttons.matching(identifier: "episode").firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 10))
        episode.tap()
        XCTAssertTrue(app.buttons["miniPlayer"].waitForExistence(timeout: 15))

        // One tap bookmarks without pausing, and the toast takes a note.
        app.buttons["Bookmark"].tap()
        let toast = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Bookmarked at'")).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Pause"].exists)
        snapshot("15 Bookmark Toast")
        app.buttons["Add Note"].tap()
        let note = app.textFields["bookmarkNote"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()
        note.typeText("great point")
        app.buttons["Save"].tap()

        // The Bookmarks tab lists it with a play button, and it exports alone or with all.
        app.tabBars.buttons["Bookmarks"].tap()
        let noteField = app.descendants(matching: .any)["bookmarkNoteField"]
        XCTAssertTrue(noteField.waitForExistence(timeout: 5))
        XCTAssertEqual(noteField.value as? String, "great point")
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
    }

    /// The first follow with + shows a one-time tip on that show's star.
    @MainActor
    func testStarTip() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxSwipe", "YES", "-hasSeenOnboarding", "NO", "-hasSeenTip.star", "NO"]
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

        // The grey ✕ closes it.
        app.buttons["Dismiss tip"].tap()
        XCTAssertTrue(tip.waitForNonExistence(timeout: 5))
    }

    /// Waits for Apple's top shows. Its chart fails now and then, so this taps Try Again a few times.
    @MainActor
    private func waitForTopShows() -> Bool {
        for _ in 0..<4 {
            let heading = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Popular now'")).firstMatch
            if heading.waitForExistence(timeout: 25) { return true }
            let retry = app.buttons["Try Again"]
            guard retry.exists else { return false }
            retry.tap()
        }
        return false
    }

    /// The first Inbox visit teaches the swipes with a one-time tip on the first row.
    @MainActor
    func testInboxSwipeTip() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-fastClock", "-hasSeenOnboarding", "YES", "-hasSeenTip.inboxSwipe", "NO"]
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
    }

    @MainActor
    private func subscribe(to address: String) {
        app.navigationBars["Shows"].buttons["Add"].tap()
        app.buttons["Add by Feed Address"].tap()
        let field = app.textFields["feedAddress"]
        field.tap()
        field.typeText(address)
        app.navigationBars["Add Show"].buttons["Subscribe"].tap()
    }

    @MainActor
    private func snapshot(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
