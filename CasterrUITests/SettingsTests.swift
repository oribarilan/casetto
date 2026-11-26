import XCTest

final class SettingsTests: UITestCase {
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

    /// A tap on Queue opens the Queue, Shows keeps its page, and a second tap on the open tab goes back to its main page.
    @MainActor
    func testTabTaps() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()
        let queueTab = app.tabBars.buttons["Queue"], showsTab = app.tabBars.buttons["Shows"]
        let settings = app.navigationBars["Settings"]

        // Second tap on Queue.
        app.navigationBars["Queue"].buttons["Settings"].tap()
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        queueTab.tap()
        XCTAssertTrue(settings.waitForNonExistence(timeout: 5), "Second tap on Queue stayed in Settings")

        // Back to the Queue from another tab.
        app.navigationBars["Queue"].buttons["Settings"].tap()
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        showsTab.tap()
        queueTab.tap()
        XCTAssertTrue(settings.waitForNonExistence(timeout: 5), "Queue tab reopened Settings")
        XCTAssertTrue(app.navigationBars["Queue"].exists)

        // Shows keeps its place.
        showsTab.tap()
        subscribe(to: feed)
        XCTAssertTrue(app.navigationBars["Add Show"].waitForNonExistence(timeout: 30))
        let tile = app.buttons["Planet Money, NPR"]
        XCTAssertTrue(tile.waitForExistence(timeout: 30))
        tile.tap()
        let showPage = app.buttons["newEpisodesRow"]
        XCTAssertTrue(showPage.waitForExistence(timeout: 5))
        queueTab.tap()
        XCTAssertTrue(app.navigationBars["Queue"].waitForExistence(timeout: 5))
        showsTab.tap()
        XCTAssertTrue(showPage.waitForExistence(timeout: 5), "Shows lost its show page")

        // Second tap on the open tab.
        showsTab.tap()
        XCTAssertTrue(showPage.waitForNonExistence(timeout: 5), "Second tap on Shows stayed on the show page")
        XCTAssertTrue(tile.exists)
    }
}
