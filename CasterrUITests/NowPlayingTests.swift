import XCTest

final class NowPlayingTests: UITestCase {
    /// Capture: bookmark while playing, add a note from the toast, find it, and export it.
    @MainActor
    func testCapture() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()

        app.tabBars.buttons["Shows"].tap()
        subscribe(to: feed)
        let show = app.buttons["Planet Money, NPR"]
        XCTAssertTrue(show.waitForExistence(timeout: 30))
        show.tap()
        let episode = app.buttons.matching(identifier: "episode").firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 10))
        episode.playFromRow()
        XCTAssertTrue(app.buttons["miniPlayer"].waitForExistence(timeout: 15))

        // One tap in Now Playing bookmarks without pausing; Add Note on the toast opens it in Bookmarks, ready to type.
        app.buttons["miniPlayer"].tap()
        let bookmark = app.buttons["Bookmark"].firstMatch
        XCTAssertTrue(bookmark.waitForExistence(timeout: 5))
        bookmark.tap()
        let toast = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Bookmarked at'")).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Pause"].firstMatch.exists)
        snapshot("15 Bookmark Toast")
        app.buttons["Add Note"].firstMatch.tap()
        let noteField = app.descendants(matching: .any)["bookmarkNoteField"]
        XCTAssertTrue(noteField.waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "no keyboard in the note")
        XCTAssertFalse(app.buttons["nowPlayingShow"].exists, "Now Playing stayed open")
        app.typeText("great point\n")

        // The Bookmarks tab lists it with a play button, and it exports alone or with all.
        let saved = XCTWaiter().wait(
            for: [
                XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == 'great point'"), object: noteField)
            ], timeout: 5)
        XCTAssertEqual(saved, .completed, "note is \(noteField.value ?? "nil")")
        let play = app.buttons["bookmarkPlay"]
        XCTAssertTrue(play.exists && play.label.hasPrefix("Play from"), play.debugDescription)
        XCTAssertTrue(app.buttons["Export"].exists)
        XCTAssertTrue(app.buttons["Export All"].exists)
        snapshot("16 Bookmarks")

        // Edit the note in place.
        noteField.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        noteField.typeText(" again")
        noteField.typeText("\n")
        let edited = NSPredicate(format: "value == 'great point again'")
        let result = XCTWaiter().wait(
            for: [XCTNSPredicateExpectation(predicate: edited, object: noteField)], timeout: 5)
        XCTAssertEqual(result, .completed, "note is \(noteField.value ?? "nil")")

        // Search covers notes.
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("GREAT")
        XCTAssertTrue(noteField.waitForExistence(timeout: 5))
        search.typeText("zzz")
        XCTAssertTrue(noteField.waitForNonExistence(timeout: 5))

        // Tapping the rest of the toast opens Bookmarks without the keyboard.
        app.buttons["Close"].firstMatch.tap()
        app.tabBars.buttons["Queue"].tap()
        // The mini player has no bookmark button, so bookmark from Now Playing again.
        XCTAssertFalse(app.buttons["Bookmark"].exists, "a bookmark button on the mini player")
        app.buttons["miniPlayer"].tap()
        app.buttons["Bookmark"].firstMatch.tap()
        let text = app.buttons["bookmarkToast"].firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        text.tap()
        XCTAssertTrue(noteField.waitForExistence(timeout: 5), "the toast didn't open Bookmarks")
        XCTAssertFalse(app.keyboards.firstMatch.exists, "the keyboard came up without Add Note")
    }

    /// ATP embeds chapters in its MP3s: the pill appears, the list shows time left, and a chapter jumps.
    @MainActor
    func testChapters() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()

        app.tabBars.buttons["Shows"].tap()
        subscribe(to: "https://atp.fm/rss")
        let show = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Accidental Tech Podcast'")).firstMatch
        XCTAssertTrue(show.waitForExistence(timeout: 30))
        show.tap()
        let episode = app.buttons.matching(identifier: "episode").firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 10))
        episode.playFromRow()
        let miniPlayer = app.buttons["miniPlayer"]
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 15))
        miniPlayer.tap()

        let pill = app.buttons["chapterPill"]
        XCTAssertTrue(pill.waitForExistence(timeout: 30), "no chapter pill")
        XCTAssertTrue(pill.label.hasPrefix("Chapter 1 of "), pill.label)
        snapshot("17 Chapter Pill")
        pill.tap()
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label ENDSWITH 'min left'")).firstMatch.waitForExistence(
                timeout: 5))
        snapshot("18 Chapters")

        // Jump to the third chapter: the elapsed time moves to its start.
        let rows = app.buttons.matching(NSPredicate(format: "label CONTAINS ', starts at '"))
        let third = rows.element(boundBy: 2)
        let start = try XCTUnwrap(third.label.components(separatedBy: ", starts at ").last)
        third.tap()
        let elapsed = app.staticTexts["elapsed"]
        XCTAssertTrue(elapsed.waitForExistence(timeout: 5))
        let atStart = NSPredicate(format: "label == %@ OR label BEGINSWITH %@", start, String(start.dropLast()))
        XCTAssertEqual(
            XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: atStart, object: elapsed)], timeout: 5),
            .completed,
            "elapsed is \(elapsed.label), chapter starts at \(start)")
        XCTAssertTrue(pill.label.hasPrefix("Chapter 3 of "), pill.label)
        sleep(3)
        snapshot("19 Chapter Pill After Jump")
        pill.tap()
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label ENDSWITH 'min left'")).firstMatch.waitForExistence(
                timeout: 5))
        snapshot("20 Chapters After Jump")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()

        // The sleep timer can stop at the end of this chapter.
        let timer = app.buttons["Sleep timer"]
        timer.tap()
        let thisChapter = app.buttons["This chapter"]
        XCTAssertTrue(thisChapter.waitForExistence(timeout: 5), "no This chapter for an episode with chapters")
        snapshot("20b Sleep Timer With Chapters")
        thisChapter.tap()
        let untilChapterEnd = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == 'Pauses at the end of the chapter'"), object: timer)
        XCTAssertEqual(
            XCTWaiter().wait(for: [untilChapterEnd], timeout: 5), .completed, "sleep timer says \(timer.value ?? "nil")"
        )
    }

    /// Now Playing's share menu offers Share Episode and Share Clip, and Share Episode opens the share sheet.
    /// The show page offers Share Show, and Share in a row's action line.
    @MainActor
    func testShareMenu() throws {
        try openATPNowPlaying()
        app.buttons["nowPlayingShare"].tap()
        let shareEpisode = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Share Episode'")).firstMatch
        XCTAssertTrue(shareEpisode.waitForExistence(timeout: 5), "no Share Episode")
        XCTAssertTrue(app.buttons["Share Clip"].exists, "no Share Clip")
        snapshot("25 Share Menu")
        shareEpisode.tap()
        let sheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 10), "Share Episode didn't open the share sheet")
        snapshot("26 Share Episode Sheet")
        // Tapping above the sheet closes it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5))

        app.swipeDown(velocity: .fast)
        XCTAssertTrue(app.navigationBars.buttons["Share Show"].waitForExistence(timeout: 5), "no Share Show")
        app.buttons.matching(identifier: "episode").firstMatch.tap()
        XCTAssertTrue(app.buttons["Share"].waitForExistence(timeout: 5), "no Share in the row's line")
    }

    /// The clip editor opens around now, an edge drag changes the length, and the length stops at 60 s.
    @MainActor
    func testClipEditor() throws {
        try openATPNowPlaying()
        // Move to the middle of the episode and pause right away. The drag must land even if it never reports its end.
        let elapsed = app.staticTexts["elapsed"]
        app.sliders.firstMatch.adjust(toNormalizedSliderPosition: 0.3)
        app.buttons["pause.circle.fill"].tap()
        let now = try XCTUnwrap(seconds(elapsed.label))
        XCTAssertGreaterThan(now, 600)
        app.buttons["nowPlayingShare"].tap()
        app.buttons["Share Clip"].tap()

        let end = app.otherElements["clipEnd"]
        XCTAssertTrue(end.waitForExistence(timeout: 20), "no bars")
        let nowLabel = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'now '")).firstMatch
        XCTAssertEqual(try XCTUnwrap(seconds(String(nowLabel.label.dropFirst(4)))), now, accuracy: 1, nowLabel.label)
        let times = app.staticTexts["clipTimes"]
        let (start, finish, length) = try clipTimes(times.label)
        XCTAssertEqual(start, now - 15, accuracy: 1.5, times.label)
        XCTAssertEqual(finish, now + 15, accuracy: 1.5, times.label)
        XCTAssertTrue((29...31).contains(length), times.label)
        // The label shows tenths, so compare to the second instead of matching rounded text.
        let endValue = try XCTUnwrap(end.value as? String)
        XCTAssertTrue(endValue.hasPrefix("Ends at "), endValue)
        XCTAssertEqual(try XCTUnwrap(seconds(String(endValue.dropFirst(8)))), finish, accuracy: 1, endValue)
        snapshot("27 Clip Editor")

        // Preview plays the fetched audio until stopped.
        let preview = app.buttons["clipPreview"]
        preview.tap()
        XCTAssertTrue(app.buttons["Stop"].waitForExistence(timeout: 3), "Preview didn't play")
        preview.tap()
        XCTAssertTrue(app.buttons["Preview"].waitForExistence(timeout: 3))

        app.buttons["clipShare"].tap()
        let sheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 30), "Share didn't open the share sheet")
        snapshot("28 Clip Share Sheet")
        app.buttons["Close"].tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5))

        let grip = end.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        grip.press(forDuration: 0.2, thenDragTo: grip.withOffset(CGVector(dx: 90, dy: 0)))
        let longer = try clipTimes(times.label).length
        XCTAssertGreaterThan(longer, length + 3, times.label)
        let movedGrip = end.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        movedGrip.press(
            forDuration: 0.2,
            thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0)).withOffset(
                CGVector(dx: 0, dy: end.frame.midY)))
        XCTAssertEqual(try clipTimes(times.label).length, 60, times.label)
        snapshot("29 Clip At Sixty")
    }

    /// Subscribes to ATP, plays its latest episode, and opens Now Playing.
    @MainActor
    private func openATPNowPlaying() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()
        app.tabBars.buttons["Shows"].tap()
        subscribe(to: "https://atp.fm/rss")
        let show = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Accidental Tech Podcast'")).firstMatch
        XCTAssertTrue(show.waitForExistence(timeout: 30))
        show.tap()
        let episode = app.buttons.matching(identifier: "episode").firstMatch
        XCTAssertTrue(episode.waitForExistence(timeout: 10))
        episode.playFromRow()
        let miniPlayer = app.buttons["miniPlayer"]
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 15))
        miniPlayer.tap()
        let share = app.buttons["nowPlayingShare"]
        XCTAssertTrue(share.waitForExistence(timeout: 10), "no share button")
        // Wait for the duration, which the editor needs.
        XCTAssertEqual(
            XCTWaiter().wait(
                for: [
                    XCTNSPredicateExpectation(
                        predicate: NSPredicate(format: "label != '0:00'"),
                        object: app.staticTexts["elapsed"])
                ], timeout: 30), .completed)
    }

    /// "12:04.4 – 12:33.8 · 0:29" as start, end and whole seconds of length.
    private func clipTimes(_ label: String) throws -> (start: TimeInterval, end: TimeInterval, length: Int) {
        let parts = label.components(separatedBy: CharacterSet(charactersIn: "–·")).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        XCTAssertEqual(parts.count, 3, label)
        return (
            try XCTUnwrap(seconds(parts[0])), try XCTUnwrap(seconds(parts[1])), Int(try XCTUnwrap(seconds(parts[2])))
        )
    }

    /// Seconds in "1:02:03", "12:04" or "12:04.4".
    private func seconds(_ clock: String) -> TimeInterval? {
        let fields = clock.split(separator: ":").map { Double($0) }
        guard !fields.isEmpty, !fields.contains(nil) else { return nil }
        return fields.compactMap(\.self).reduce(0) { $0 * 60 + $1 }
    }

    /// Headphone and car buttons: the footer says what each press does and follows a change.
    @MainActor
    func testHeadphoneButtons() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-hasSeenTip.inboxCardSwipe", "YES", "-hasSeenOnboarding", "YES"]
        app.launch()
        app.navigationBars.buttons["Settings"].tap()
        let footer = app.staticTexts["buttonsFooter"]
        for _ in 0..<6 where !footer.isHittable { app.swipeUp() }
        XCTAssertTrue(footer.waitForExistence(timeout: 5), "no Headphone and car buttons footer")
        XCTAssertTrue(
            footer.label.hasPrefix("Double press bookmarks, with a chime. Triple press skips back 15."), footer.label)
        snapshot("29 Headphone Buttons")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Triple press'")).firstMatch.tap()
        let skipForward = app.buttons["Skip forward 30"]
        XCTAssertTrue(skipForward.waitForExistence(timeout: 5), "the Triple press menu didn't open")
        skipForward.tap()
        let changed = NSPredicate(format: "label CONTAINS 'Triple press skips forward 30.'")
        expectation(for: changed, evaluatedWith: footer)
        waitForExpectations(timeout: 5)
    }
}
