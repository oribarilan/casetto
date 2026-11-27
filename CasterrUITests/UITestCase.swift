import XCTest

/// Walks the screens against their spec scenarios and saves a screenshot of each.
/// Needs network: it subscribes to a real public feed.
class UITestCase: XCTestCase {
    let feed = "https://feeds.npr.org/510289/podcast.xml"
    var app: XCUIApplication!

    /// Waits for Apple's top shows. Its chart fails now and then, so this taps Try Again a few times.
    @MainActor
    func waitForTopShows() -> Bool {
        for _ in 0..<4 {
            // Plain text, or a menu outside the United States.
            let heading = app.descendants(matching: .any).matching(
                NSPredicate(format: "label BEGINSWITH 'Popular now'")
            ).firstMatch
            if heading.waitForExistence(timeout: 25) { return true }
            let retry = app.buttons["Try Again"]
            guard retry.exists else { return false }
            retry.tap()
        }
        return false
    }

    @MainActor
    func subscribe(to address: String) {
        app.navigationBars["Shows"].buttons["Add"].tap()
        app.buttons["Add by Feed Address"].tap()
        let field = app.textFields["feedAddress"]
        field.tap()
        field.typeText(address)
        app.navigationBars["Add Show"].buttons["Follow"].tap()
    }

    @MainActor
    /// Taps the open menu's choice named `title`, with or without its explanation after it.
    func choose(_ title: String) {
        let predicate = NSPredicate(format: "label == %@ OR label BEGINSWITH %@", title, title + ", ")
        let choice = app.buttons.matching(predicate).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5), "no \(title) in the menu")
        choice.tap()
    }

    @MainActor
    func snapshot(_ name: String) {
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
