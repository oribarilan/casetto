import Foundation
import Testing
@testable import CasterrCore

struct ClipWindowTests {
    let hour: TimeInterval = 3600

    @Test func opensAroundNowInTheMiddle() {
        let window = ClipWindow(position: 739, duration: hour) // 12:19
        #expect(window.span == 679...799)
        #expect(window.defaultClip == 724...754)
    }

    @Test func nearTheStartShiftsLater() {
        let window = ClipWindow(position: 5, duration: hour)
        #expect(window.span == 0...120)
        #expect(window.defaultClip == 0...30)
    }

    @Test func nearTheEndShiftsEarlier() {
        let window = ClipWindow(position: 3590, duration: hour)
        #expect(window.span == 3480...3600)
        #expect(window.defaultClip == 3570...3600)
    }

    @Test func aShortEpisodeIsAllSpan() {
        let window = ClipWindow(position: 45, duration: 90)
        #expect(window.span == 0...90)
        #expect(window.defaultClip == 30...60)
        let tiny = ClipWindow(position: 10, duration: 20)
        #expect(tiny.span == 0...20)
        #expect(tiny.defaultClip == 0...20)
    }

    @Test func dragsStopAtSixtySeconds() {
        let window = ClipWindow(position: 739, duration: hour)
        #expect(window.dragging(.start, of: 724...754, to: 679) == 694...754)
        #expect(window.dragging(.end, of: 724...754, to: 799) == 724...784)
    }

    @Test func dragsStopAtFiveSeconds() {
        let window = ClipWindow(position: 739, duration: hour)
        #expect(window.dragging(.start, of: 724...754, to: 752) == 749...754)
        #expect(window.dragging(.end, of: 724...754, to: 700) == 724...729)
    }

    @Test func dragsStayWithinTheSpan() {
        let window = ClipWindow(position: 5, duration: hour)
        #expect(window.dragging(.start, of: 10...30, to: -10) == 0...30)
        #expect(window.dragging(.end, of: 80...100, to: 130) == 80...120)
    }

    @Test func freeDragMovesOnlyOneEdge() {
        let window = ClipWindow(position: 739, duration: hour)
        #expect(window.dragging(.start, of: 724...754, to: 720.5) == 720.5...754)
        #expect(window.dragging(.end, of: 724...754, to: 760) == 724...760)
    }

    @Test func byteRangeForAConstantBitrateFile() {
        let window = ClipWindow(position: 739, duration: hour)
        #expect(window.fetchSpan == 677...801)
        // 128 kbps is 16,000 bytes a second.
        #expect(window.byteRange(totalBytes: 57_600_000, id3TagSize: 0) == 10_832_000...12_816_000)
    }

    @Test func byteRangeSkipsTheID3Tag() {
        let window = ClipWindow(position: 739, duration: hour)
        #expect(window.byteRange(totalBytes: 57_700_000, id3TagSize: 100_000) == 10_932_000...12_916_000)
    }

    @Test func byteRangeStaysWithinTheFile() {
        let end = ClipWindow(position: 3590, duration: hour)
        #expect(end.byteRange(totalBytes: 57_600_000, id3TagSize: 0) == 55_648_000...57_599_999)
        let start = ClipWindow(position: 5, duration: hour)
        #expect(start.byteRange(totalBytes: 57_600_000, id3TagSize: 0) == 0...1_952_000)
    }

    @Test func noByteRangeWithoutADuration() {
        #expect(ClipWindow(position: 5, duration: 0).byteRange(totalBytes: 1000, id3TagSize: 0) == nil)
        #expect(ClipWindow(position: 5, duration: 60).byteRange(totalBytes: 1000, id3TagSize: 1000) == nil)
    }
}

struct LoudnessBarsTests {
    /// Alternating ±amplitude, whose RMS is the amplitude.
    func tone(_ amplitude: Float, count: Int) -> [Float] {
        (0..<count).map { $0.isMultiple(of: 2) ? amplitude : -amplitude }
    }

    @Test func barsFollowDecibels() {
        let samples = tone(1, count: 200) + tone(0.1, count: 100) + tone(0.001, count: 100)
        let bars = LoudnessBars.bars(from: samples, count: 4)
        #expect(bars.count == 4)
        #expect(abs(bars[0] - 1) < 0.001 && abs(bars[1] - 1) < 0.001)
        #expect(abs(bars[2] - (1 - 20 / LoudnessBars.range)) < 0.001) // 20 dB down
        #expect(bars[3] == 0) // 60 dB down, past the range
    }

    @Test func loudnessIsRelativeToTheLoudestBar() {
        let bars = LoudnessBars.bars(from: tone(0.01, count: 100) + tone(0.001, count: 100), count: 2)
        #expect(abs(bars[0] - 1) < 0.001)
        #expect(abs(bars[1] - (1 - 20 / LoudnessBars.range)) < 0.001)
    }

    @Test func silenceIsZero() {
        #expect(LoudnessBars.bars(from: Array(repeating: 0, count: 100), count: 4) == [0, 0, 0, 0])
        #expect(LoudnessBars.bars(from: [], count: 3) == [0, 0, 0])
        #expect(LoudnessBars.bars(from: tone(1, count: 10), count: 0) == [])
    }
}
