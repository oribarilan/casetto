import XCTest

/// Needs network: subscribes to a real public feed and streams one episode.
final class SmokeTests: XCTestCase {
    private let feed = "https://feeds.npr.org/510289/podcast.xml"

    @MainActor
    func testSubscribePlayAndQueue() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        app.navigationBars["Queue"].buttons["Shows"].tap()
        app.navigationBars["Shows"].buttons["Add"].tap()
        app.buttons["Add by Feed Address"].tap()
        let address = app.textFields["feedAddress"]
        address.tap()
        address.typeText(feed)
        app.buttons["Subscribe"].tap()

        let show = app.cells.firstMatch
        XCTAssertTrue(show.waitForExistence(timeout: 30), "show didn't appear after subscribing")
        show.tap()

        let firstEpisode = app.buttons.matching(identifier: "episode").firstMatch
        XCTAssertTrue(firstEpisode.waitForExistence(timeout: 10))
        firstEpisode.tap()

        // Streaming: elapsed time advances in Now Playing.
        let miniPlayer = app.buttons["miniPlayer"]
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 15), "playback didn't start")
        miniPlayer.tap()
        let elapsed = app.staticTexts["elapsed"]
        XCTAssertTrue(elapsed.waitForExistence(timeout: 10))
        let start = elapsed.label
        let advanced = NSPredicate(format: "label != %@", start)
        expectation(for: advanced, evaluatedWith: elapsed)
        waitForExpectations(timeout: 30)

        // 2x for all shows, then check it still plays.
        app.buttons["speed"].tap()
        app.sliders["speedSlider"].adjust(toNormalizedSliderPosition: 1.0)
        app.buttons["All shows"].tap()
        app.buttons["Done"].tap()
        let speed = app.buttons["speed"]
        let atDoubleSpeed = speed.wait(for: \.label, toEqual: "2.0×", timeout: 10)
        XCTAssertTrue(atDoubleSpeed, "speed button says \(speed.label)")
        let atTwo = elapsed.label
        expectation(for: NSPredicate(format: "label != %@", atTwo), evaluatedWith: elapsed)
        waitForExpectations(timeout: 15)

        // The played episode is Now Playing at the top of the Queue.
        app.swipeDown(velocity: .fast)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Now Playing"].waitForExistence(timeout: 10))
    }
}
