import Foundation
import Testing
@testable import CasterrCore

struct QuietGapsTests {
    @Test func findsTheMiddleOfEveryGapInOrder() {
        let readings = speech(from: 0, to: 10, quiet: [6.0...6.19, 2.0...2.19]).reversed()
        let gaps = QuietGaps.find(in: Array(readings))
        #expect(gaps.count == 2)
        #expect(abs(gaps[0] - 2.1) < 0.011 && abs(gaps[1] - 6.1) < 0.011)
    }

    @Test func noReadingsNoGaps() {
        #expect(QuietGaps.find(in: []).isEmpty)
        #expect(QuietGaps.find(in: [], neighborhood: QuietGaps.editorNeighborhood).isEmpty)
    }

    @Test func neighborhoodFindsAGapInAQuietStretchNextToALoudOne() {
        let readings = speech(from: 0, to: 14, level: 0.6)
            + speech(from: 14, to: 20, level: 0.03, quiet: [18.0...18.19], quietLevel: 0.003)
        let local = QuietGaps.find(in: readings, neighborhood: QuietGaps.editorNeighborhood)
        #expect(local.count == 1)
        #expect(abs((local.first ?? 0) - 18.1) < 0.011)
        // Against one median, the loud stretch makes the whole quiet stretch one gap.
        #expect(!QuietGaps.find(in: readings).contains { abs($0 - 18.1) < 0.5 })
    }
}

struct ClipSnapTests {
    let window = ClipWindow(position: 739, duration: 3600) // 12:19

    @Test func snapsToAGapWithinHalfASecond() {
        // A pause from 12:03.1 to 12:03.3.
        #expect(ClipWindow.snap(723.6, to: [723.2]) == 723.2)
    }

    @Test func pullsFreeBeyondHalfASecond() {
        #expect(ClipWindow.snap(722.5, to: [723.2]) == 722.5)
    }

    @Test func snapsToTheNearestGap() {
        #expect(ClipWindow.snap(10, to: [9.7, 10.2, 30]) == 10.2)
    }

    @Test func defaultClipSnapsBothEdges() {
        #expect(window.snappedDefaultClip(to: [700, 724.4, 740, 753.8]) == 724.4...753.8)
    }

    @Test func defaultClipWithNoGapNearbyStaysPut() {
        #expect(window.snappedDefaultClip(to: [700, 740, 800]) == window.defaultClip)
        #expect(window.snappedDefaultClip(to: []) == window.defaultClip)
    }

    @Test func snappedDefaultClipKeepsTheLimits() {
        let short = ClipWindow(position: 2.75, duration: 5.5)
        let clip = short.snappedDefaultClip(to: [0.4, 5.1])
        #expect(clip.lowerBound == 0.4)
        #expect(clip.upperBound - clip.lowerBound >= ClipWindow.shortest - 1e-9)
        #expect(clip.upperBound <= short.span.upperBound)

        let start = ClipWindow(position: 5, duration: 3600)
        #expect(start.snappedDefaultClip(to: [-0.3, 30.2]) == 0...30.2)
    }
}
