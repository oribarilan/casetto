import XCTest

final class SharingTests: UITestCase {
    /// A shared audio file arrives in the Queue, plays, and lives on the Shared with Casterr page.
    @MainActor
    func testSharedFile() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        let fixture = try XCTUnwrap(Bundle(for: Self.self).path(forResource: "shared-interview", ofType: "m4a"))
        app.launchEnvironment = ["SHARED_FIXTURE": fixture, "SHARED_FIXTURE_TITLE": "Interview with Dana"]
        app.launch()

        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Interview with Dana'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "shared file isn't in the Queue")
        snapshot("21 Shared In Queue")
        app.buttons["upNextPlay"].tap()
        let miniPlayer = app.buttons["miniPlayer"]
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 10))
        miniPlayer.tap()
        let elapsed = app.staticTexts["elapsed"]
        XCTAssertTrue(elapsed.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["nowPlayingShare"].exists, "a shared file offers sharing")
        let advanced = NSPredicate(format: "label != '0:00'")
        XCTAssertEqual(
            XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: advanced, object: elapsed)], timeout: 10),
            .completed,
            "shared file didn't play")
        snapshot("22 Shared Now Playing")

        // It lives on the Shared with Casterr page, where Delete removes it everywhere.
        app.swipeDown(velocity: .fast)
        app.tabBars.buttons["Shows"].tap()
        let sharedShow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Shared with Casterr'")).firstMatch
        XCTAssertTrue(sharedShow.waitForExistence(timeout: 5), "no Shared with Casterr in the grid")
        sharedShow.tap()
        let episode = app.buttons.matching(identifier: "episode").firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["followShow"].exists, "the built-in show offers Follow")
        XCTAssertFalse(app.navigationBars.buttons["Share Show"].exists, "the built-in show offers Share Show")
        episode.tap()
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Share"].exists, "a shared file offers Share")
        episode.tap()
        XCTAssertTrue(app.buttons["Delete"].waitForNonExistence(timeout: 5))
        snapshot("23 Shared With Casterr")
        episode.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(episode.waitForNonExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Queue"].tap()
        XCTAssertTrue(app.staticTexts["Silence. Lovely, but let's fix that."].waitForExistence(timeout: 5))
    }

    /// A shared Apple Podcasts episode plays next; its show's page offers Follow until you do.
    @MainActor
    func testSharedLinkAndSubscribe() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launchEnvironment = [
            "SHARED_LINK": "https://podcasts.apple.com/us/podcast/two-hot-streaks/id617416468?i=1000801592580"
        ]
        app.launch()

        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Two Hot Streaks'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 30), "shared episode isn't in the Queue")
        app.buttons["upNextPlay"].tap()
        app.buttons["miniPlayer"].tap()
        let showName = app.buttons["nowPlayingShow"]
        XCTAssertTrue(showName.waitForExistence(timeout: 10))
        showName.tap()

        let follow = app.buttons["followShow"]
        XCTAssertTrue(follow.waitForExistence(timeout: 10), "no Follow on an unfollowed show")
        XCTAssertEqual(follow.label, "Follow")
        XCTAssertTrue(app.buttons["starShow"].exists)
        snapshot("24 Unfollowed Show")
        follow.tap()
        // The settings show while the feed still downloads.
        XCTAssertTrue(app.buttons["newEpisodesRow"].exists, "the settings waited for the follow")
        XCTAssertEqual(app.buttons["newEpisodesRow"].value as? String, "Inbox")
        XCTAssertTrue(app.buttons["removedAfterRow"].exists)
        XCTAssertEqual(follow.label, "Following")
    }
}
