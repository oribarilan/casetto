import Foundation
import Testing
@testable import CasterrCore

@MainActor
private final class FakeEngine: AudioEngine {
    var onTime: ((TimeInterval, TimeInterval?) -> Void)?
    var onEnd: (() -> Void)?
    var onFailure: ((any Error) -> Void)?

    private(set) var loaded: (url: URL, position: TimeInterval)?
    private(set) var rate: Double?
    private(set) var seekedTo: TimeInterval?

    func load(_ url: URL, at position: TimeInterval) { loaded = (url, position) }
    func play(rate: Double) { self.rate = rate }
    func pause() { rate = nil }
    func seek(to position: TimeInterval) { seekedTo = position }
}

private let show = ShowKey(feedURL: URL(string: "https://example.com/feed")!)!

@MainActor
private struct Harness {
    let library: Library
    let engine = FakeEngine()
    let player: Player
    let episodes: [EpisodeInfo]

    init(
        sleep: @escaping @Sendable (Duration) async throws -> Void = { _ in },
        localFile: @escaping (EpisodeKey, URL) -> URL? = { _, _ in nil }
    ) async throws {
        library = try Library.open(inMemory: true)
        try await library.addSubscription(show, feedURL: URL(string: "https://example.com/feed")!)
        try await library.saveFeed(try FeedParser.parse(fixture("podcast.xml")), for: show)
        episodes = try await library.episodes(of: show)
        player = Player(library: library, engine: engine, sleep: sleep, localFile: localFile)
    }

    /// Waits for work the player starts on its own (engine callbacks spawn tasks).
    func settle() async {
        for _ in 0..<20 { await Task.yield() }
        _ = try? await library.queue()
    }
}

@MainActor
struct PlayerTests {
    @Test func playMovesToTopAndStartsFromSavedPosition() async throws {
        let h = try await Harness()
        try await h.library.addToQueue(h.episodes[0].key)
        try await h.library.setProgress(h.episodes[1].key, to: 1390)

        try await h.player.play(h.episodes[1].key)

        #expect(try await h.library.queue() == [h.episodes[1].key, h.episodes[0].key])
        #expect(h.engine.loaded?.url == h.episodes[1].audioURL)
        #expect(h.engine.loaded?.position == 1390)
        #expect(h.player.isPlaying)
    }

    @Test func downloadedEpisodePlaysFromItsFile() async throws {
        let file = URL(filePath: "/tmp/downloaded.mp3")
        let h = try await Harness(localFile: { key, _ in key.rawValue.hasSuffix("tape-hiss-3") ? file : nil })
        try await h.player.play(h.episodes[0].key)
        #expect(h.engine.loaded?.url == file)
        try await h.player.play(h.episodes[1].key)
        #expect(h.engine.loaded?.url == h.episodes[1].audioURL)
    }

    @Test func playsAtTheEffectiveSpeed() async throws {
        let h = try await Harness()
        try await h.library.setGlobalSpeed(PlaybackSpeed(1.5))
        try await h.player.play(h.episodes[0].key)
        #expect(h.engine.rate == 1.5)
    }

    @Test func pauseSavesProgress() async throws {
        let h = try await Harness()
        try await h.player.play(h.episodes[0].key)
        h.engine.onTime?(1390, 3000)
        try await h.player.pause()
        #expect(try await h.library.progress(of: h.episodes[0].key) == 1390)
        #expect(!h.player.isPlaying)
    }

    @Test func progressIsSavedEveryFewSeconds() async throws {
        let h = try await Harness()
        try await h.player.play(h.episodes[0].key)
        h.engine.onTime?(2, 3000)
        h.engine.onTime?(6, 3000)
        await h.settle()
        #expect(try await h.library.progress(of: h.episodes[0].key) == 6)
    }

    @Test func endingArchivesAndStartsTheNextEpisode() async throws {
        let h = try await Harness()
        try await h.library.addToQueue(h.episodes[0].key)
        try await h.library.addToQueue(h.episodes[1].key)
        try await h.player.resume()

        h.engine.onEnd?()
        await h.settle()

        #expect(try await h.library.place(of: h.episodes[0].key) == .archive(.played))
        #expect(try await h.library.queue() == [h.episodes[1].key])
        #expect(h.player.episode?.key == h.episodes[1].key)
        #expect(h.engine.loaded?.url == h.episodes[1].audioURL)
    }

    @Test func startingPlaybackRecordsTheFirstStartOnce() async throws {
        let h = try await Harness()
        try await h.library.addToQueue(h.episodes[0].key)
        try await h.library.addToQueue(h.episodes[1].key)
        #expect(try await h.library.firstPlayedAt(of: h.episodes[0].key) == nil)

        try await h.player.resume()
        let first = try #require(try await h.library.firstPlayedAt(of: h.episodes[0].key))
        h.engine.onEnd?()
        await h.settle()
        #expect(try await h.library.firstPlayedAt(of: h.episodes[1].key) != nil)

        try await h.player.play(h.episodes[0].key)
        #expect(try await h.library.firstPlayedAt(of: h.episodes[0].key) == first)
    }

    @Test func lastEpisodeEndingMarksTheQueueRunOut() async throws {
        let h = try await Harness()
        try await h.library.addToQueue(h.episodes[0].key)
        try await h.player.resume()
        #expect(h.player.queueRanOutAt == nil)
        h.engine.onEnd?()
        await h.settle()
        #expect(h.player.queueRanOutAt != nil)
    }

    @Test func endOfEpisodeTimerDoesNotMarkTheQueueRunOut() async throws {
        let h = try await Harness()
        try await h.library.addToQueue(h.episodes[0].key)
        try await h.player.resume()
        h.player.setSleepTimer(.endOfEpisode)
        h.engine.onEnd?()
        await h.settle()
        #expect(h.player.queueRanOutAt == nil)
    }

    @Test func skipForwardAndBack() async throws {
        let h = try await Harness()
        try await h.player.play(h.episodes[0].key)
        h.engine.onTime?(100, 3000)
        h.player.skipForward()
        #expect(h.engine.seekedTo == 130)
        h.player.skipBack()
        #expect(h.engine.seekedTo == 115)
    }

    @Test func skipBackNearTheStartGoesToTheStart() async throws {
        let h = try await Harness()
        try await h.player.play(h.episodes[0].key)
        h.engine.onTime?(10, 3000)
        h.player.skipBack()
        #expect(h.engine.seekedTo == 0)
    }

    @Test func skipForwardNearTheEndGoesToTheEnd() async throws {
        let h = try await Harness()
        try await h.player.play(h.episodes[0].key)
        h.engine.onTime?(2990, 3000)
        h.player.skipForward()
        #expect(h.engine.seekedTo == 3000)
    }

    @Test func failingAudioShowsAMessageAndLeavesTheQueue() async throws {
        let h = try await Harness()
        try await h.player.play(h.episodes[0].key)
        h.engine.onFailure?(URLError(.badServerResponse))
        #expect(h.player.errorMessage == "This episode wouldn't play. Its audio may have moved.")
        #expect(!h.player.isPlaying)
        #expect(try await h.library.queue() == [h.episodes[0].key])
    }

    @Test func offlineShowsTheOfflineMessage() async throws {
        let h = try await Harness()
        try await h.player.play(h.episodes[0].key)
        h.engine.onFailure?(URLError(.notConnectedToInternet))
        #expect(h.player.errorMessage == "You're offline, and this one isn't downloaded yet.")
    }
}

@MainActor
struct SleepTimerTests {
    @Test func durationTimerPauses() async throws {
        let h = try await Harness(sleep: { _ in })
        try await h.player.play(h.episodes[0].key)
        h.player.setSleepTimer(.duration(.seconds(15 * 60)))
        await h.settle()
        #expect(!h.player.isPlaying)
        #expect(h.player.sleepTimer == nil)
    }

    @Test func cancelledTimerKeepsPlaying() async throws {
        let h = try await Harness(sleep: { try await Task.sleep(for: .seconds($0.components.seconds)) })
        try await h.player.play(h.episodes[0].key)
        h.player.setSleepTimer(.duration(.seconds(15 * 60)))
        h.player.setSleepTimer(nil)
        await h.settle()
        #expect(h.player.isPlaying)
        #expect(h.player.sleepTimerEndsAt == nil)
    }

    @Test func durationTimerKnowsWhenItEnds() async throws {
        let h = try await Harness(sleep: { try await Task.sleep(for: .seconds($0.components.seconds)) })
        try await h.player.play(h.episodes[0].key)
        h.player.setSleepTimer(.duration(.seconds(30 * 60)))
        let left = try #require(h.player.sleepTimerEndsAt).timeIntervalSinceNow
        #expect(abs(left - 30 * 60) < 5)
        h.player.setSleepTimer(.endOfEpisode)
        #expect(h.player.sleepTimerEndsAt == nil)
    }

    @Test func endOfEpisodePausesWithoutStartingTheNext() async throws {
        let h = try await Harness()
        try await h.library.addToQueue(h.episodes[0].key)
        try await h.library.addToQueue(h.episodes[1].key)
        try await h.player.resume()
        h.player.setSleepTimer(.endOfEpisode)

        h.engine.onEnd?()
        await h.settle()

        #expect(!h.player.isPlaying)
        #expect(h.engine.loaded?.url == h.episodes[0].audioURL)
        #expect(try await h.library.queue() == [h.episodes[1].key])
        #expect(h.player.sleepTimer == nil)

        try await h.player.resume()
        #expect(h.engine.loaded?.url == h.episodes[1].audioURL)
    }
}
