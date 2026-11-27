import Foundation
import Testing

@testable import CasterrCore

struct ShowNotesChaptersTests {
    @Test func readsAHebrewList() throws {
        let notes = try #require(String(data: try fixture("hebrew-show-notes.html"), encoding: .utf8))
        let chapters = ShowNotesChapters.parse(notes, duration: 57 * 60 + 22)
        #expect(chapters.count == 10)
        #expect(chapters.first == Chapter(start: 0, title: "פתיחה"))
        #expect(chapters[2] == Chapter(start: 5 * 60 + 51, title: "מכוניות חשמליות"))
        #expect(chapters.last == Chapter(start: 53 * 60 + 19, title: "סיכום ופרידה"))
    }

    @Test func readsHoursInParentheses() {
        let notes = "<p>(00:00:00) Introduction<br>(00:12:30) Sleep and light<br />(1:02:03) Questions</p>"
        #expect(ShowNotesChapters.parse(notes, duration: nil).map(\.start) == [0, 750, 3723])
    }

    @Test func allowsSeparatorsAndBrackets() {
        let notes = "<ul><li>[0:00] - Intro</li><li>5:00 – Main topic</li><li>12:00 | Wrap&amp;up</li></ul>"
        #expect(ShowNotesChapters.parse(notes, duration: nil).map(\.title) == ["Intro", "Main topic", "Wrap&up"])
    }

    @Test func aSingleTimeIsNotAList() {
        #expect(ShowNotesChapters.parse("<p>Intro</p><p>5:00 The main part</p>", duration: nil).isEmpty)
    }

    @Test func timesInProseDoNotCount() {
        let notes = "<p>We recorded this at 9:30 after the show.</p><p>Back at 10:15 next week.</p>"
        #expect(ShowNotesChapters.parse(notes, duration: nil).isEmpty)
    }

    @Test func aDateLineDoesNotCount() {
        #expect(ShowNotesChapters.parse("09:00:00 -0000\n10:00:00 +0200", duration: nil).isEmpty)
    }

    @Test func outOfOrderEntriesAreDropped() {
        let notes = "0:00 Intro\n10:00 Second\n5:00 Stray\n20:00 Third"
        #expect(ShowNotesChapters.parse(notes, duration: nil).map(\.title) == ["Intro", "Second", "Third"])
    }

    @Test func aRepeatedListCountsOnce() {
        let notes = "0:00 Intro\n2:30 News\n5:51 Main\n0:00 Intro\n2:30 News\n5:51 Main"
        #expect(ShowNotesChapters.parse(notes, duration: nil).count == 3)
    }

    @Test func aTimeBeyondTheEpisodeMeansNoChapters() {
        #expect(ShowNotesChapters.parse("0:00 Intro\n70:00 Late", duration: 3600).isEmpty)
    }
}

struct ChapterProgressTests {
    let chapters = [
        Chapter(start: 0, title: "פתיחה"), Chapter(start: 150, title: "וויקלי סינק"),
        Chapter(start: 351, title: "ג׳נסן שובב"), Chapter(start: 1225, title: "וויקס"),
    ]

    @Test func insideTheThirdChapter() {
        let progress = ChapterProgress(chapters: chapters, position: 612, duration: 3442)
        #expect(progress.current == 2)
        #expect(progress.fractions[0] == 1 && progress.fractions[1] == 1 && progress.fractions[3] == 0)
        #expect(abs(progress.fractions[2] - 0.2986) < 0.001)
        #expect(progress.minutesLeft == 11)  // 10:13 left
    }

    @Test func atABoundaryTheNextChapterStartsEmpty() {
        let progress = ChapterProgress(chapters: chapters, position: 1225, duration: 3442)
        #expect(progress.current == 3)
        #expect(progress.fractions[2] == 1 && progress.fractions[3] == 0)
    }

    @Test func beforeTheFirstChapter() {
        let late = [Chapter(start: 30, title: "A"), Chapter(start: 90, title: "B")]
        let progress = ChapterProgress(chapters: late, position: 10, duration: 200)
        #expect(progress.current == nil && progress.minutesLeft == nil && progress.fractions == [0, 0])
    }

    @Test func neverZeroMinutesLeft() {
        #expect(ChapterProgress(chapters: chapters, position: 1224.5, duration: 3442).minutesLeft == 1)
    }

    @Test func lastChapterWithAndWithoutADuration() {
        let known = ChapterProgress(chapters: chapters, position: 2333.5, duration: 3442)
        #expect(abs(known.fractions[3] - 0.5) < 0.001 && known.minutesLeft == 19)
        let unknown = ChapterProgress(chapters: chapters, position: 2333.5, duration: nil)
        #expect(unknown.fractions[3] == 0 && unknown.minutesLeft == nil)
    }
}
