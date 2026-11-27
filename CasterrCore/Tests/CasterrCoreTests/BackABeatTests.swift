import Foundation
import Testing

@testable import CasterrCore

/// Readings every 10 ms from `start` to `end` at `level`, with `quiet` stretches at `quietLevel`.
func speech(
    from start: TimeInterval, to end: TimeInterval, level: Float = 0.3,
    quiet: [ClosedRange<TimeInterval>] = [], quietLevel: Float = 0.005
) -> [Loudness] {
    stride(from: 0, to: Int(((end - start) / Loudness.slice).rounded()), by: 1).map { index in
        let time = start + Double(index) * Loudness.slice
        let isQuiet = quiet.contains { $0.contains(time + 0.0001) }
        return Loudness(time: time, level: isQuiet ? quietLevel : level)
    }
}

struct BackABeatTests {
    let pausedAt: TimeInterval = 1390  // 23:10

    @Test func resumesInTheMiddleOfAGap() {
        let readings = speech(from: 1382, to: 1390, quiet: [1386.9...1387.09])
        #expect(abs(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) - 1387) < 0.011)
    }

    @Test func theLatestGapWins() {
        let readings = speech(from: 1382, to: 1390, quiet: [1385.4...1385.59, 1387.3...1387.49])
        #expect(abs(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) - 1387.4) < 0.011)
    }

    @Test func gapsOutsideTheStretchDoNotCount() {
        let readings = speech(from: 1382, to: 1390, quiet: [1384.0...1384.2, 1388.5...1388.7])
        #expect(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) == pausedAt)
    }

    @Test func noQuietGapResumesAtThePausePoint() {
        let readings = speech(from: 1382, to: 1390, quiet: [1386.0...1386.2], quietLevel: 0.2)
        #expect(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) == pausedAt)
    }

    @Test func aGapTooShortDoesNotCount() {
        let readings = speech(from: 1382, to: 1390, quiet: [1386.0...1386.12])
        #expect(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) == pausedAt)
    }

    @Test func quietIsJudgedAgainstTheStretch() {
        let loud = speech(from: 1382, to: 1390, level: 0.6, quiet: [1387.0...1387.2], quietLevel: 0.04)
        let soft = speech(from: 1382, to: 1390, level: 0.03, quiet: [1387.0...1387.2], quietLevel: 0.002)
        #expect(BackABeat.resumePoint(pausedAt: pausedAt, readings: loud) != pausedAt)
        #expect(BackABeat.resumePoint(pausedAt: pausedAt, readings: soft) != pausedAt)
    }

    @Test func missingReadingsBreakAGap() {
        let readings = speech(from: 1382, to: 1390, quiet: [1387.0...1387.3])
            .filter { !(1387.1...1387.2).contains($0.time) }
        #expect(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) == pausedAt)
    }

    @Test func noReadingsResumesAtThePausePoint() {
        #expect(BackABeat.resumePoint(pausedAt: pausedAt, readings: []) == pausedAt)
    }

    @Test func nearTheStartNeverGoesBeforeZero() {
        #expect(BackABeat.resumePoint(pausedAt: 1, readings: speech(from: 0, to: 1)) == 1)
        let early = speech(from: 0, to: 4, quiet: [0.5...0.7])
        let point = BackABeat.resumePoint(pausedAt: 4, readings: early)
        #expect(point >= 0 && abs(point - 0.6) < 0.011)
    }
}

/// Edge cases from the "it doesn't go back, or goes forward" report. The pause point is 23:10 (1390).
/// Tests named `desired...` assert the listener's request rather than the current spec text.
struct BackABeatEdgeTests {
    let pausedAt: TimeInterval = 1390

    // MARK: The pause lands inside a gap

    @Test func desiredPauseInsideALongGapGoesBackToTheGapBeforeIt() {
        // The listener pauses 2.6 s into a long pause between phrases. There is an earlier gap at 23:04.1.
        let readings = speech(from: 1378, to: 1391, quiet: [1384.0...1384.19, 1387.4...1390.5])
        let point = BackABeat.resumePoint(pausedAt: pausedAt, readings: readings)
        #expect(point < 1387.4, "resumed at \(point), inside the gap the pause landed in")
    }

    @Test func desiredPauseInsideAGapThatReachesTheWindowGoesBackToTheGapBeforeIt() {
        // The gap that holds the pause point started 2.2 s before it. An earlier gap is at 23:05.1.
        let readings = speech(from: 1378, to: 1391, quiet: [1385.0...1385.19, 1387.8...1390.4])
        let point = BackABeat.resumePoint(pausedAt: pausedAt, readings: readings)
        #expect(point < 1387.8, "resumed at \(point), inside the gap the pause landed in")
    }

    @Test func pauseInsideAShortGapUsesAnEarlierGap() {
        let readings = speech(from: 1382, to: 1391, quiet: [1386.0...1386.19, 1389.8...1390.2])
        #expect(abs(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) - 1386.1) < 0.011)
    }

    // MARK: Window edges

    @Test func aGapRightAtTheNearEdgeCounts() {
        let readings = speech(from: 1382, to: 1390, quiet: [1387.8...1387.999])
        #expect(abs(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) - 1387.9) < 0.011)
    }

    @Test func aGapRightAtTheFarEdgeCounts() {
        let readings = speech(from: 1382, to: 1390, quiet: [1385.0...1385.199])
        #expect(abs(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) - 1385.1) < 0.011)
    }

    @Test func aGapWhoseMiddleIsJustInsideTheNearEdgeCounts() {
        // Quiet from 1387.88 to 1388.09: 0.21 s, middle 1387.985, which is 2.015 s before the pause.
        let readings = speech(from: 1382, to: 1390, quiet: [1387.88...1388.08])
        let point = BackABeat.resumePoint(pausedAt: pausedAt, readings: readings)
        #expect(abs(point - 1387.985) < 0.02, "resumed at \(point)")
    }

    @Test func aGapWhoseMiddleIsJustInsideTheFarEdgeCounts() {
        // Quiet from 1384.92 to 1385.11: 0.19 s, middle 1385.015, which is 4.985 s before the pause.
        let readings = speech(from: 1382, to: 1390, quiet: [1384.92...1385.10])
        let point = BackABeat.resumePoint(pausedAt: pausedAt, readings: readings)
        #expect(abs(point - 1385.015) < 0.02, "resumed at \(point)")
    }

    @Test func aGapThatStartsBeforeTheWindowAndEndsWellInsideItResumesInTheGap() {
        let readings = speech(from: 1382, to: 1390, quiet: [1384.4...1385.4])
        let point = BackABeat.resumePoint(pausedAt: pausedAt, readings: readings)
        #expect(point >= 1384.4 && point <= 1385.41, "resumed at \(point)")
    }

    @Test func aGapThatStartsBeforeTheWindowAndEndsJustInsideItResumesInTheGap() {
        // A 0.6 s pause between phrases whose last 0.1 s is inside the window: resume inside it, at the window's edge.
        let readings = speech(from: 1382, to: 1390, quiet: [1384.5...1385.09])
        let point = BackABeat.resumePoint(pausedAt: pausedAt, readings: readings)
        #expect(point >= 1384.5 && point <= 1385.1, "resumed at \(point)")
    }

    // MARK: Quiet judged against the stretch

    @Test func gapsThatFillMoreThanHalfTheStretchStillCount() {
        // A slow speaker: 1.6 s of the 3 s stretch is pauses, so the median is the quiet level.
        let readings = speech(from: 1382, to: 1390, quiet: [1385.2...1385.99, 1386.5...1387.29])
        let point = BackABeat.resumePoint(pausedAt: pausedAt, readings: readings)
        #expect(abs(point - 1386.9) < 0.011, "resumed at \(point)")
    }

    @Test func desiredSilenceAcrossTheWholeWindowGoesBackBeforeTheSilence() {
        // Speech stops at 23:04.5 and the listener pauses 5.5 s into the silence. A gap at 23:01 precedes it.
        let readings = speech(from: 1376, to: 1391, quiet: [1381.0...1381.19, 1384.5...1391])
        let point = BackABeat.resumePoint(pausedAt: pausedAt, readings: readings)
        #expect(point < 1384.5, "resumed at \(point)")
    }

    @Test func digitalSilenceInAGapCounts() {
        let readings = speech(from: 1382, to: 1390, quiet: [1387.0...1387.19], quietLevel: 0)
        #expect(abs(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) - 1387.1) < 0.011)
    }

    // MARK: Short gaps

    @Test func aGapOfExactlyTheShortestLengthCounts() {
        let readings = speech(from: 1382, to: 1390, quiet: [1387.0...1387.149])
        #expect(abs(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) - 1387.075) < 0.011)
    }

    @Test func aGapOneSliceShorterDoesNotCount() {
        let readings = speech(from: 1382, to: 1390, quiet: [1387.0...1387.139])
        #expect(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) == pausedAt)
    }

    @Test func stopsInsideWordsDoNotCount() {
        let stops = stride(from: 1385.2, to: 1387.9, by: 0.3).map { $0...($0 + 0.08) }
        let readings = speech(from: 1382, to: 1390, quiet: stops)
        #expect(BackABeat.resumePoint(pausedAt: pausedAt, readings: readings) == pausedAt)
    }

    // MARK: Speeds

    /// Readings spaced as the app's audio tap spaces them at `rate`: whole frames per slice.
    private func tapReadings(rate: Double, sampleRate: Double, quiet: ClosedRange<TimeInterval>) -> [Loudness] {
        let step = (sampleRate * Loudness.slice / rate).rounded() * rate / sampleRate
        return stride(from: 1382.0, to: 1390, by: step).map {
            Loudness(time: $0, level: quiet.contains($0) ? 0.005 : 0.3)
        }
    }

    @Test(arguments: [44_100.0, 48_000.0])
    func findsTheGapAtEverySpeed(sampleRate: Double) {
        for tenths in 10...20 {
            let rate = Double(tenths) / 10
            let readings = tapReadings(rate: rate, sampleRate: sampleRate, quiet: 1387.0...1387.2)
            let point = BackABeat.resumePoint(pausedAt: pausedAt, readings: readings)
            #expect(abs(point - 1387.1) < 0.02, "at \(rate)x and \(sampleRate) Hz it resumed at \(point)")
        }
    }

    // MARK: Never forward

    @Test func neverResumesAtOrAfterThePausePointExceptToStayPut() {
        var generator = SystemRandomNumberGenerator()
        for _ in 0..<300 {
            let pause = Double.random(in: 0...20, using: &generator)
            let gaps = (0..<4).map { _ -> ClosedRange<TimeInterval> in
                let start = Double.random(in: 0...20, using: &generator)
                return start...(start + Double.random(in: 0.05...3, using: &generator))
            }
            let readings = speech(from: 0, to: 21, quiet: gaps)
            let point = BackABeat.resumePoint(pausedAt: pause, readings: readings)
            #expect(
                point == pause || (point >= 0 && point < pause - BackABeat.nearest + Loudness.slice),
                "paused at \(pause), resumed at \(point)")
        }
    }
}
