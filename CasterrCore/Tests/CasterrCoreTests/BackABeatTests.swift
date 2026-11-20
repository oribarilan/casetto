import Foundation
import Testing
@testable import CasterrCore

/// Readings every 10 ms from `start` to `end` at `level`, with `quiet` stretches at `quietLevel`.
func speech(from start: TimeInterval, to end: TimeInterval, level: Float = 0.3,
            quiet: [ClosedRange<TimeInterval>] = [], quietLevel: Float = 0.005) -> [Loudness] {
    stride(from: 0, to: Int(((end - start) / Loudness.slice).rounded()), by: 1).map { index in
        let time = start + Double(index) * Loudness.slice
        let isQuiet = quiet.contains { $0.contains(time + 0.0001) }
        return Loudness(time: time, level: isQuiet ? quietLevel : level)
    }
}

struct BackABeatTests {
    let pausedAt: TimeInterval = 1390 // 23:10

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
