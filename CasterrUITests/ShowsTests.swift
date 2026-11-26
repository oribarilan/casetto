import XCTest

final class ShowsTests: UITestCase {
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

    /// Outside the United States, the heading switches the chart to the United States, and the choice is kept.
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
}
