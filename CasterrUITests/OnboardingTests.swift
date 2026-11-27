import XCTest

final class OnboardingTests: UITestCase {
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

    /// The first follow with + shows a one-time tip on that show's star.
    @MainActor
    func testStarTip() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "NO", "-hasSeenTip.star", "NO",
        ]
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

    /// After an update, Cassy offers What's New; Settings ends with the version, which opens it too.
    @MainActor
    func testWhatsNew() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES",
            "-lastSeenVersion", "0.1",
        ]
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
        XCTAssertFalse(
            app.staticTexts["VERSION 0.1"].exists || app.staticTexts["Version 0.1"].exists, "lists 0.1, already seen")
        snapshot("29 Whats New")
        app.navigationBars["What's New"].buttons["Done"].tap()

        app.navigationBars.buttons["Settings"].tap()
        let version = app.buttons["version"]
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(version.waitForExistence(timeout: 3), "no version in Settings")
        let current = Bundle(for: Self.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        XCTAssertTrue(version.label.contains("Version \(current)"), "\(version.label) is not \(current)")
        version.tap()
        XCTAssertTrue(app.navigationBars["What's New"].waitForExistence(timeout: 3))
        let first = { [app] in app!.staticTexts["VERSION 0.1"].exists || app!.staticTexts["Version 0.1"].exists }
        for _ in 0..<4 where !first() { app.swipeUp() }
        XCTAssertTrue(first(), "Settings should list every version")
    }
}
