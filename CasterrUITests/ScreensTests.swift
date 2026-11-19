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
        app.launchArguments = ["-uiTesting"]
        app.launch()

        // Queue is the home screen; empty state links to shows.
        XCTAssertTrue(app.staticTexts["Nothing queued"].waitForExistence(timeout: 5))
        snapshot("1 Empty Queue")
        app.buttons["Your Shows"].tap()
        XCTAssertTrue(app.staticTexts["No shows yet"].waitForExistence(timeout: 5))

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

        // Show page: add three episodes to the Queue, mark the third played.
        show.tap()
        let episodes = app.buttons.matching(identifier: "episode")
        XCTAssertTrue(episodes.firstMatch.waitForExistence(timeout: 10))
        for index in 0..<3 {
            episodes.element(boundBy: index).swipeRight()
            app.buttons["Add to Queue"].tap()
        }
        XCTAssertTrue(app.staticTexts["Queued"].waitForExistence(timeout: 5))
        episodes.element(boundBy: 2).swipeLeft()
        app.buttons["Mark Played"].tap()
        XCTAssertTrue(app.staticTexts["Played"].waitForExistence(timeout: 5))
        snapshot("4 Show Page")

        // Unsubscribe keeps queued episodes.
        app.navigationBars.buttons["More"].tap()
        app.buttons["Unsubscribe"].tap()
        app.buttons.matching(identifier: "Unsubscribe").element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["No shows yet"].waitForExistence(timeout: 10))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Queue: two items in the order added; remove the second.
        let queue = app.buttons.matching(identifier: "queueItem")
        XCTAssertTrue(queue.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(queue.count, 2)
        XCTAssertTrue(app.staticTexts["Now Playing"].exists)
        snapshot("5 Queue")
        queue.element(boundBy: 1).swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertEqual(queue.count, 1)

        // Downloads: the top of the Queue downloads on Wi-Fi, and Off deletes it.
        let downloaded = app.images["Downloaded"]
        XCTAssertTrue(downloaded.waitForExistence(timeout: 120))
        snapshot("5b Downloaded")
        app.navigationBars.buttons["Downloads"].tap()
        app.buttons["Off"].tap()
        XCTAssertTrue(downloaded.waitForNonExistence(timeout: 10))

        // Now Playing: play, sleep timer.
        queue.firstMatch.tap()
        let miniPlayer = app.buttons["miniPlayer"]
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 15))
        miniPlayer.tap()
        app.buttons["Sleep timer"].tap()
        app.buttons["15 minutes"].tap()
        XCTAssertTrue(app.buttons["Sleep timer on"].waitForExistence(timeout: 5))
        snapshot("6 Now Playing")
        app.buttons["speed"].tap()
        snapshot("7 Speed")
    }

    /// Inbox triage. `-fastClock` makes one second pass as one day.
    @MainActor
    func testInbox() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-fastClock"]
        app.launch()

        // Subscribing puts the newest episode in the Inbox.
        XCTAssertTrue(app.buttons["Your Shows"].waitForExistence(timeout: 5))
        app.buttons["Your Shows"].tap()
        subscribe(to: feed)
        XCTAssertTrue(app.buttons["Planet Money, NPR"].waitForExistence(timeout: 30))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let newRow = app.buttons["New (1)"]
        XCTAssertTrue(newRow.waitForExistence(timeout: 5))
        snapshot("8 New Row")
        newRow.tap()
        XCTAssertTrue(app.buttons.matching(identifier: "inboxItem").firstMatch.waitForExistence(timeout: 5))
        app.navigationBars.buttons["Expiry"].tap()
        XCTAssertTrue(app.buttons["7 days"].waitForExistence(timeout: 5))
        snapshot("9 Inbox Expiry")
        app.buttons["7 days"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // After more than 7 days, a refresh expires it.
        sleep(8)
        let list = app.collectionViews.firstMatch
        list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            .press(forDuration: 0, thenDragTo: list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)))
        XCTAssertTrue(newRow.waitForNonExistence(timeout: 30))

        // The show page explains the move and offers Undo.
        app.buttons["Your Shows"].tap()
        app.buttons["Planet Money, NPR"].tap()
        XCTAssertTrue(app.staticTexts["Expired after 7 days"].waitForExistence(timeout: 5))
        snapshot("10 Expired")
        app.buttons["Undo"].tap()
        XCTAssertTrue(app.staticTexts["In Inbox"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Undo"].exists)

        // Triage controls: expiry applies to Inbox shows only.
        let expiryPicker = app.descendants(matching: .any)["expiryPicker"]
        XCTAssertTrue(expiryPicker.exists)
        app.descendants(matching: .any)["levelPicker"].tap()
        app.buttons["Play Next"].tap()
        XCTAssertTrue(expiryPicker.waitForNonExistence(timeout: 5))
        snapshot("11 Show Triage")

        // Dismiss from the Inbox.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(newRow.waitForExistence(timeout: 5))
        newRow.tap()
        let item = app.buttons.matching(identifier: "inboxItem").firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.swipeLeft()
        app.buttons["Dismiss"].tap()
        XCTAssertTrue(app.staticTexts["Inbox is empty"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func subscribe(to address: String) {
        app.navigationBars["Shows"].buttons["Add"].tap()
        app.buttons["Add by Feed Address"].tap()
        let field = app.textFields["feedAddress"]
        field.tap()
        field.typeText(address)
        app.buttons["Subscribe"].tap()
    }

    @MainActor
    private func snapshot(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
