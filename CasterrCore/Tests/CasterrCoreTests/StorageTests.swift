import Foundation
import SwiftData
import Testing
@testable import CasterrCore

private let show = ShowKey(feedURL: URL(string: "https://example.com/feed")!)!
private let feedURL = URL(string: "https://example.com/feed")!

private func episode(_ n: Int) -> EpisodeKey {
    EpisodeKey(show: show, guid: "ep\(n)", audioURL: URL(string: "https://cdn.example.com/\(n).mp3")!)
}

private func queuedLibrary(_ count: Int) async throws -> Library {
    let library = try Library.open(inMemory: true)
    for n in 1...count { try await library.addToQueue(episode(n)) }
    return library
}

struct UserDataSchemaTests {
    @Test(arguments: Schemas.userData.entities)
    func followsCloudKitRules(entity: Schema.Entity) {
        #expect(entity.relationships.isEmpty, "\(entity.name) has relationships")
        #expect(entity.uniquenessConstraints.isEmpty, "\(entity.name) has uniqueness constraints")
        for attribute in entity.attributes {
            #expect(!attribute.isUnique, "\(entity.name).\(attribute.name) is unique")
            #expect(attribute.isOptional || attribute.defaultValue != nil,
                    "\(entity.name).\(attribute.name) has no default and isn't optional")
        }
    }
}

struct SubscriptionStoreTests {
    @Test func subscribingTwiceKeepsOneRecord() async throws {
        let library = try Library.open(inMemory: true)
        #expect(try await library.addSubscription(show, feedURL: feedURL))
        #expect(try await !library.addSubscription(show, feedURL: feedURL))
        #expect(try await library.subscriptions().count == 1)
    }

    @Test func feedMoveKeepsTheShowKey() async throws {
        let library = try Library.open(inMemory: true)
        try await library.addSubscription(show, feedURL: feedURL)
        let moved = URL(string: "https://new-host.com/feed")!
        try await library.updateFeedURL(show, to: moved)
        #expect(try await library.subscriptions() == [SubscriptionInfo(showKey: show, feedURL: moved, speedOverride: nil)])
    }

    @Test func unsubscribeKeepsQueuedEpisodes() async throws {
        let library = try await queuedLibrary(2)
        try await library.addSubscription(show, feedURL: feedURL)
        try await library.removeSubscription(show)
        #expect(try await library.subscriptions().isEmpty)
        #expect(try await library.queue() == [episode(1), episode(2)])
    }
}

struct QueueStoreTests {
    @Test func addAppendsToTheEnd() async throws {
        let library = try await queuedLibrary(3)
        #expect(try await library.queue() == [episode(1), episode(2), episode(3)])
        #expect(try await library.place(of: episode(1)) == .queue)
    }

    @Test func addingAQueuedEpisodeChangesNothing() async throws {
        let library = try await queuedLibrary(3)
        try await library.addToQueue(episode(1))
        #expect(try await library.queue() == [episode(1), episode(2), episode(3)])
    }

    @Test func addingAnArchivedEpisodeTakesItOutOfTheArchive() async throws {
        let library = try Library.open(inMemory: true)
        try await library.markPlayed(episode(1))
        try await library.addToQueue(episode(1))
        #expect(try await library.place(of: episode(1)) == .queue)
    }

    @Test func moveKeepsTheOthersInOrder() async throws {
        let library = try await queuedLibrary(5)
        try await library.move(episode(4), to: 1)
        #expect(try await library.queue() == [episode(1), episode(4), episode(2), episode(3), episode(5)])
    }

    @Test func moveToTopAddsAndPutsFirst() async throws {
        let library = try await queuedLibrary(2)
        try await library.moveToTop(episode(9))
        #expect(try await library.queue() == [episode(9), episode(1), episode(2)])
    }

    @Test func moveToTopFromLowerInTheQueue() async throws {
        let library = try await queuedLibrary(3)
        try await library.moveToTop(episode(3))
        #expect(try await library.queue() == [episode(3), episode(1), episode(2)])
    }

    @Test func removeLeavesNoPlaceAndKeepsProgress() async throws {
        let library = try await queuedLibrary(2)
        try await library.setProgress(episode(1), to: 300)
        try await library.removeFromQueue(episode(1))
        #expect(try await library.queue() == [episode(2)])
        #expect(try await library.place(of: episode(1)) == nil)
        #expect(try await library.progress(of: episode(1)) == 300)
    }
}

struct EpisodeStateStoreTests {
    @Test func markPlayedArchivesAndLeavesTheQueue() async throws {
        let library = try await queuedLibrary(3)
        try await library.markPlayed(episode(1))
        #expect(try await library.place(of: episode(1)) == .archive(.played))
        #expect(try await library.queue() == [episode(2), episode(3)])
    }

    @Test func markUnplayedClearsTheArchiveAndProgress() async throws {
        let library = try Library.open(inMemory: true)
        try await library.setProgress(episode(1), to: 1200)
        try await library.markPlayed(episode(1))
        try await library.markUnplayed(episode(1))
        #expect(try await library.place(of: episode(1)) == nil)
        #expect(try await library.progress(of: episode(1)) == 0)
    }

    @Test func untouchedEpisodeHasNoPlaceAndNoProgress() async throws {
        let library = try Library.open(inMemory: true)
        #expect(try await library.place(of: episode(1)) == nil)
        #expect(try await library.progress(of: episode(1)) == 0)
    }
}

struct SettingsStoreTests {
    @Test func defaultSpeedIsNormal() async throws {
        let library = try Library.open(inMemory: true)
        #expect(try await library.globalSpeed() == .normal)
    }

    @Test func effectiveSpeedUsesOverrideThenGlobal() async throws {
        let library = try Library.open(inMemory: true)
        try await library.addSubscription(show, feedURL: feedURL)
        try await library.setGlobalSpeed(PlaybackSpeed(1.5))
        #expect(try await library.effectiveSpeed(for: show) == PlaybackSpeed(1.5))
        try await library.setSpeedOverride(show, to: .normal)
        #expect(try await library.effectiveSpeed(for: show) == .normal)
        try await library.setSpeedOverride(show, to: nil)
        #expect(try await library.effectiveSpeed(for: show) == PlaybackSpeed(1.5))
    }
}

struct FeedCacheStoreTests {
    @Test func savesShowAndEpisodesNewestFirst() async throws {
        let library = try Library.open(inMemory: true)
        let feed = try FeedParser.parse(fixture("podcast.xml"))
        try await library.saveFeed(feed, for: show)
        #expect(try await library.show(show)?.title == feed.title)
        let dates = try await library.episodes(of: show).map { $0.publishDate ?? .distantPast }
        #expect(dates.count == feed.episodes.count)
        #expect(dates == dates.sorted(by: >))
    }

    @Test func savingTheSameFeedTwiceCreatesNoDuplicates() async throws {
        let library = try Library.open(inMemory: true)
        let feed = try FeedParser.parse(fixture("podcast.xml"))
        try await library.saveFeed(feed, for: show)
        try await library.saveFeed(feed, for: show)
        #expect(try await library.episodes(of: show).count == feed.episodes.count)
    }

    @Test func wipingTheFeedCacheKeepsUserDataPointingAtTheRightEpisodes() async throws {
        let library = try Library.open(inMemory: true)
        let feed = try FeedParser.parse(fixture("no-guids.xml"))
        try await library.addSubscription(show, feedURL: feedURL)
        try await library.saveFeed(feed, for: show)
        let first = try #require(try await library.episodes(of: show).first)
        try await library.addToQueue(first.key)
        try await library.setProgress(first.key, to: 42)

        try await library.wipeFeedCache()
        #expect(try await library.episode(first.key) == nil)
        try await library.saveFeed(try FeedParser.parse(fixture("no-guids.xml")), for: show)

        let queued = try #require(try await library.queue().first)
        #expect(try await library.episode(queued)?.title == first.title)
        #expect(try await library.progress(of: queued) == 42)
        #expect(try await library.subscriptions().count == 1)
    }
}
