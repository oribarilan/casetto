import XCTest

/// Needs network: subscribes to a real public feed and streams one episode.
final class SmokeTests: XCTestCase {
    private let feed = "https://feeds.npr.org/510289/podcast.xml"

    @MainActor
    func testSubscribePlayAndQueue() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()

        app.tabBars.buttons["Shows"].tap()
        app.navigationBars["Shows"].buttons["Add"].tap()
        app.buttons["Add by Feed Address"].tap()
        let address = app.textFields["feedAddress"]
        address.tap()
        address.typeText(feed)
        app.navigationBars["Add Show"].buttons["Follow"].tap()

        let show = app.buttons["Planet Money, NPR"]
        XCTAssertTrue(show.waitForExistence(timeout: 30), "show didn't appear after subscribing")
        show.tap()

        let firstEpisode = app.buttons.matching(identifier: "episode").firstMatch
        XCTAssertTrue(firstEpisode.waitForExistence(timeout: 10))
        firstEpisode.playFromRow()

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

        // 2x for this show applies right away and turns "Use my default" off by itself, then check it still plays.
        app.buttons["speed"].tap()
        let slider = app.sliders["speedSlider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5), "no slider in the speed sheet")
        let useDefault = app.switches["useMyDefault"]
        XCTAssertEqual(useDefault.value as? String, "1")
        slider.adjust(toNormalizedSliderPosition: 1.0)
        XCTAssertTrue(waitForValue("0", of: useDefault), "moving the slider left Use my default on")
        closeSheet()
        let speed = app.buttons["speed"]
        let atDoubleSpeed = speed.wait(for: \.label, toEqual: "2.0×", timeout: 10)
        XCTAssertTrue(atDoubleSpeed, "speed button says \(speed.label)")
        let atTwo = elapsed.label
        expectation(for: NSPredicate(format: "label != %@", atTwo), evaluatedWith: elapsed)
        waitForExpectations(timeout: 15)

        // Turning "Use my default" back on returns to the default speed.
        speed.tap()
        XCTAssertTrue(useDefault.waitForExistence(timeout: 5))
        useDefault.switches.firstMatch.tap()
        closeSheet()
        XCTAssertTrue(speed.wait(for: \.label, toEqual: "1.0×", timeout: 10), "speed button says \(speed.label)")

        // Voice boost for this show applies right away, then follows the default again.
        let boost = app.buttons["voiceBoost"]
        XCTAssertEqual(boost.value as? String, "Off")
        boost.tap()
        let picker = app.segmentedControls["voiceBoostPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "no voice boost sheet")
        picker.buttons["On"].tap()
        XCTAssertTrue(waitForValue("0", of: useDefault), "picking On left Use my default on")
        closeSheet()
        XCTAssertTrue(waitForValue("On", of: boost), "voice boost says \(boost.value ?? "nil")")
        boost.tap()
        XCTAssertTrue(useDefault.waitForExistence(timeout: 5))
        useDefault.switches.firstMatch.tap()
        closeSheet()
        XCTAssertTrue(waitForValue("Off", of: boost), "voice boost says \(boost.value ?? "nil")")

        // The played episode is playing at the top of the Queue.
        app.swipeDown(velocity: .fast)
        app.tabBars.buttons["Queue"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Playing'")).firstMatch.waitForExistence(timeout: 10))

        // Turning voice boost on in Settings reaches a show that follows the default.
        app.navigationBars.buttons["Settings"].tap()
        let boostDefault = app.switches["voiceBoostDefault"]
        XCTAssertTrue(boostDefault.waitForExistence(timeout: 5))
        boostDefault.switches.firstMatch.tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["miniPlayer"].tap()
        XCTAssertTrue(waitForValue("On", of: boost), "voice boost says \(boost.value ?? "nil")")
    }

    /// Closes a control sheet by tapping above it.
    @MainActor
    private func closeSheet() {
        XCUIApplication().coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()
    }

    @MainActor
    private func waitForValue(_ value: String, of element: XCUIElement) -> Bool {
        let matches = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: element)
        return XCTWaiter().wait(for: [matches], timeout: 5) == .completed
    }
}
