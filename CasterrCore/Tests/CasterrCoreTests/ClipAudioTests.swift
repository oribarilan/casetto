import Foundation
import Testing
@testable import CasterrCore

struct LoudnessReadingsTests {
    @Test func oneReadingPerTenMillisecondsTimedFromTheStart() {
        // 25 ms at 1 kHz: 10 samples a reading, the last 5 samples dropped.
        let samples = [Float](repeating: 0.5, count: 10) + [Float](repeating: 0, count: 10) + [Float](repeating: 1, count: 5)
        let readings = Loudness.readings(from: samples, sampleRate: 1000, startingAt: 677)
        #expect(readings == [Loudness(time: 677, level: 0.5), Loudness(time: 677.01, level: 0)])
    }

    @Test func levelIsTheRootMeanSquare() {
        let readings = Loudness.readings(from: [1, -1, 1, -1, 0, 0, 0, 0, 0, 0], sampleRate: 1000, startingAt: 0)
        #expect(abs((readings.first?.level ?? 0) - Float(0.4).squareRoot()) < 0.0001)
    }

    @Test func noSamplesNoReadings() {
        #expect(Loudness.readings(from: [], sampleRate: 44_100, startingAt: 0).isEmpty)
    }
}

struct MP3HeaderTests {
    @Test func id3SizeIsSyncsafePlusTheHeader() {
        // 0x01 0x7F = 1 << 7 | 127 = 255 bytes of tag after the 10-byte header.
        let header = Data([0x49, 0x44, 0x33, 4, 0, 0, 0, 0, 0x01, 0x7F])
        #expect(MP3Header.id3TagSize(header) == 265)
    }

    @Test func id3FooterAddsTenBytes() {
        #expect(MP3Header.id3TagSize(Data([0x49, 0x44, 0x33, 4, 0, 0x10, 0, 0, 0, 5])) == 25)
    }

    @Test func noTagIsZeroAndTooFewBytesIsNil() {
        #expect(MP3Header.id3TagSize(Data([0xFF, 0xFB, 0x90, 0x64, 0, 0, 0, 0, 0, 0])) == 0)
        #expect(MP3Header.id3TagSize(Data([0x49, 0x44, 0x33])) == nil)
    }

    @Test func xingAfterAStereoMPEG1HeaderIsVariable() {
        #expect(MP3Header.isVariableBitrate(frame([0xFF, 0xFB, 0x90, 0x64], marker: "Xing", at: 36)) == true)
    }

    @Test func xingAfterAMonoMPEG1HeaderIsVariable() {
        #expect(MP3Header.isVariableBitrate(frame([0xFF, 0xFB, 0x90, 0xC4], marker: "Xing", at: 21)) == true)
    }

    @Test func vbriIsVariable() {
        #expect(MP3Header.isVariableBitrate(frame([0xFF, 0xFB, 0x90, 0x64], marker: "VBRI", at: 36)) == true)
    }

    @Test func infoOrNoMarkerIsConstant() {
        // LAME writes "Info" in the Xing spot of a constant-bitrate file.
        #expect(MP3Header.isVariableBitrate(frame([0xFF, 0xFB, 0x90, 0x64], marker: "Info", at: 36)) == false)
        #expect(MP3Header.isVariableBitrate(frame([0xFF, 0xFB, 0x90, 0x64], marker: nil, at: 0)) == false)
    }

    @Test func findsTheFrameAfterPadding() {
        let padded = Data(repeating: 0, count: 7) + frame([0xFF, 0xFB, 0x90, 0x64], marker: "Xing", at: 36)
        #expect(MP3Header.isVariableBitrate(padded) == true)
    }

    @Test func noFrameIsNil() {
        #expect(MP3Header.isVariableBitrate(Data(repeating: 0, count: 64)) == nil)
    }

    // Built like ATP 718's failing part: an MPEG-2 header at 9 that's really audio data, then 64 kbps
    // MPEG-1 frames from 140. The episode's first frame, the reference, is the same format unpadded.
    private let reference = Data([0xFF, 0xFB, 0x50, 0xC4] + [UInt8](repeating: 0, count: 60))
    private let paddedFrame = [0xFF, 0xFB, 0x52, 0xC4] + [UInt8](repeating: 0, count: 205) // 209 bytes

    @Test func skipsBytesThatOnlyLookLikeAFrame() {
        var lead = [UInt8](repeating: 0x11, count: 140)
        lead.replaceSubrange(9..<13, with: [0xFF, 0xF3, 0x52, 0x7A])
        let part = Data(lead + paddedFrame + paddedFrame + paddedFrame)
        let first = MP3Header.firstFrame(in: part, like: reference)
        #expect(first?.offset == 140)
        #expect(first?.bitrate == 64_000)
    }

    @Test func aLoneLookalikeWithoutASecondFrameIsSkipped() {
        // The same format, but nothing where its frame would end.
        let part = Data([0x11, 0xFF, 0xFB, 0x50, 0xC4] + [UInt8](repeating: 0x11, count: 300) + paddedFrame + paddedFrame)
        #expect(MP3Header.firstFrame(in: part, like: reference)?.offset == 305)
    }

    @Test func aPartThatStartsOnAFrameKeepsEveryByte() {
        let part = Data(paddedFrame + paddedFrame)
        #expect(MP3Header.firstFrame(in: part, like: reference)?.offset == 0)
    }

    @Test func noMatchingFrameIsNil() {
        #expect(MP3Header.firstFrame(in: Data(repeating: 0x11, count: 1000), like: reference) == nil)
        #expect(MP3Header.firstFrame(in: Data(paddedFrame + paddedFrame), like: Data(repeating: 0, count: 64)) == nil)
    }

    private func frame(_ header: [UInt8], marker: String?, at offset: Int) -> Data {
        var bytes = header + [UInt8](repeating: 0, count: 60)
        if let marker { bytes.replaceSubrange(offset ..< offset + 4, with: Array(marker.utf8)) }
        return Data(bytes)
    }
}
