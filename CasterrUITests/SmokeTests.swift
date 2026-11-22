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

        // 2x for this show applies right away, then check it still plays.
        app.buttons["speed"].tap()
        let useDefault = app.switches.firstMatch
        XCTAssertTrue(useDefault.waitForExistence(timeout: 5))
        useDefault.switches.firstMatch.tap()
        let slider = app.sliders["speedSlider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5), "turning off the default didn't show the slider")
        slider.adjust(toNormalizedSliderPosition: 1.0)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()
        let speed = app.buttons["speed"]
        let atDoubleSpeed = speed.wait(for: \.label, toEqual: "2.0×", timeout: 10)
        XCTAssertTrue(atDoubleSpeed, "speed button says \(speed.label)")
        let atTwo = elapsed.label
        expectation(for: NSPredicate(format: "label != %@", atTwo), evaluatedWith: elapsed)
        waitForExpectations(timeout: 15)

        // Voice boost for this show applies right away, then follows the default again.
        let boost = app.buttons["voiceBoost"]
        XCTAssertEqual(boost.value as? String, "Off, your default")
        boost.tap()
        app.buttons["On for this show"].tap()
        let onForShow = NSPredicate(format: "value == 'On, for this show'")
        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: onForShow, object: boost)], timeout: 5), .completed,
                       "voice boost says \(boost.value ?? "nil")")
        boost.tap()
        app.buttons["Use my default (Off)"].tap()
        let followsDefault = NSPredicate(format: "value == 'Off, your default'")
        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: followsDefault, object: boost)], timeout: 5), .completed,
                       "voice boost says \(boost.value ?? "nil")")

        // The played episode is playing at the top of the Queue.
        app.swipeDown(velocity: .fast)
        app.tabBars.buttons["Queue"].tap()
        XCTAssertTrue(app.staticTexts["Playing"].waitForExistence(timeout: 10))

        // Turning voice boost on in Settings reaches a show that follows the default.
        app.navigationBars.buttons["Settings"].tap()
        let boostDefault = app.switches["voiceBoostDefault"]
        XCTAssertTrue(boostDefault.waitForExistence(timeout: 5))
        boostDefault.switches.firstMatch.tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["miniPlayer"].tap()
        let boostOnByDefault = NSPredicate(format: "value == 'On, your default'")
        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: boostOnByDefault, object: boost)], timeout: 5), .completed,
                       "voice boost says \(boost.value ?? "nil")")
    }
}
