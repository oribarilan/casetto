import Foundation
import Testing
@testable import CasterrCore

struct DownloadSizeTests {
    private func episode(bytes: Int64? = nil, minutes: Double? = nil) -> EpisodeInfo {
        let show = ShowKey(rawValue: "https://example.com/feed.xml")
        let audio = URL(string: "https://example.com/\(UUID().uuidString).mp3")!
        return EpisodeInfo(key: EpisodeKey(show: show, guid: nil, audioURL: audio), showKey: show, title: "x",
                           audioURL: audio, duration: minutes.map { $0 * 60 }, byteLength: bytes)
    }

    @Test func addsUpTheFeedSizes() {
        #expect(DownloadSize.estimate([episode(bytes: 70_000_000), episode(bytes: 70_000_000), episode(bytes: 70_000_000)]) == 210_000_000)
    }

    @Test func estimatesFromTheLengthWithoutASize() {
        #expect(DownloadSize.estimate([episode(minutes: 60)]) == 57_600_000)
    }

    @Test func estimatesFromTheLengthWhenTheSizeIsImplausible() {
        #expect(DownloadSize.estimate([episode(bytes: 0, minutes: 60), episode(bytes: 3000, minutes: 60)]) == 115_200_000)
    }

    @Test func countsNothingWithoutSizeOrLength() {
        #expect(DownloadSize.estimate([episode()]) == 0)
        #expect(DownloadSize.estimate([]) == 0)
    }

    @Test func captionSaysTheSizeForTheChoice() {
        let queue = [episode(bytes: 70_000_000), episode(bytes: 70_000_000), episode(bytes: 70_000_000), episode(bytes: 70_000_000)]
        #expect(DownloadSize.caption(queue, count: 3) == "About 210 MB for the top 3.")
        #expect(DownloadSize.caption(queue, count: 1) == "About 70 MB for the top episode.")
        #expect(DownloadSize.caption(queue, count: 10) == "About 280 MB for the top 10.")
    }

    @Test func captionUsesGigabytesAboveOne() {
        #expect(DownloadSize.caption(Array(repeating: episode(bytes: 120_000_000), count: 10), count: 10) == "About 1.2 GB for the top 10.")
    }

    @Test func captionIsEmptyForOffOrNothing() {
        #expect(DownloadSize.caption([episode(bytes: 70_000_000)], count: 0) == nil)
        #expect(DownloadSize.caption([], count: 3) == nil)
    }
}
