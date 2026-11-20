import Foundation
import Synchronization
import Testing
@testable import CasterrCore

private let show = ShowKey(feedURL: URL(string: "https://example.com/feed")!)!

private func key(_ n: Int) -> EpisodeKey {
    EpisodeKey(show: show, guid: "ep\(n)", audioURL: URL(string: "https://cdn.example.com/\(n).mp3")!)
}

/// Two libraries on one store folder stand in for two devices that wrote before syncing.
private func twoDevices() throws -> (Library, Library) {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return (try Library.open(directory: folder), try Library.open(directory: folder))
}

private func at(_ seconds: TimeInterval) -> @Sendable () -> Date {
    { Date(timeIntervalSince1970: 1_800_000_000 + seconds) }
}

struct SyncMergeTests {
    @Test func librariesOnOneFolderShareData() async throws {
        let (a, b) = try twoDevices()
        try await a.addToQueue(key(1))
        #expect(try await b.queue() == [key(1)])
    }

    @Test func latestMoveWinsAndEarliestFirstPlayIsKept() async throws {
        let (a, b) = try twoDevices()
        await a.useClock(at(0))
        await b.useClock(at(60))
        try await a.recordPlayStart(key(1))
        try await a.dismiss(key(1))
        // Device b hadn't seen a's state: it queued and played the episode a minute later.
        try await b.insertStateForTesting(key(1), place: .queue, queuePosition: 1, firstPlayedAt: at(60)())

        try await a.mergeDuplicates()
        #expect(try await a.place(of: key(1)) == .queue)
        #expect(try await a.firstPlayedAt(of: key(1)) == at(0)())
        #expect(try await a.stateCountForTesting(key(1)) == 1)
    }

    @Test func earliestSubscriptionWins() async throws {
        let (a, b) = try twoDevices()
        await a.useClock(at(0))
        await b.useClock(at(60))
        try await a.addSubscription(show, feedURL: URL(string: show.rawValue)!)
        try await a.setLevel(show, to: .autoQueue)
        try await b.insertSubscriptionForTesting(show)
        #expect(try await a.subscriptions().count == 2)
        try await a.mergeDuplicates()
        #expect(try await a.subscriptions().map(\.level) == [.autoQueue])
    }

    @Test func changedSettingsWinOverANewDevicesDefaults() async throws {
        let (a, b) = try twoDevices()
        try await a.setGlobalSpeed(PlaybackSpeed(1.5))
        try await b.insertDefaultSettingsForTesting()
        try await b.mergeDuplicates()
        #expect(try await b.globalSpeed() == PlaybackSpeed(1.5))
    }

    @Test func queueRenumbersWithTiesGoingToTheLaterMove() async throws {
        let (a, b) = try twoDevices()
        await a.useClock(at(0))
        await b.useClock(at(60))
        try await a.addToQueue(key(1))
        try await a.addToQueue(key(2))
        // Device b queued episode 3 into position 2 before seeing a's episode 2.
        try await b.insertStateForTesting(key(3), place: .queue, queuePosition: 2)
        try await a.mergeDuplicates()
        #expect(try await a.queue() == [key(1), key(3), key(2)])
    }
}
