import XCTest

final class InboxTests: UITestCase {
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
}
