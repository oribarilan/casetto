import XCTest

/// Walks the M1 screens against their spec scenarios and saves a screenshot of each.
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
