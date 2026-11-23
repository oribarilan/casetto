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
    @Test func playableQueueSkipsEpisodesThisDeviceDoesNotHave() async throws {
        let library = try Library.open(inMemory: true)
        try await library.addSubscription(show, feedURL: feedURL)
        try await library.saveFeed(try FeedParser.parse(fixture("podcast.xml")), for: show)
        let known = try await library.episodes(of: show).map(\.key)
        let elsewhere = EpisodeKey(rawValue: "casterr:shared|guid:shared-1")
        try await library.addToQueue(known[0])
        try await library.addToQueue(elsewhere)
        try await library.addToQueue(known[1])
        #expect(try await library.queue() == [known[0], elsewhere, known[1]])
        #expect(try await library.playableQueue() == [known[0], known[1]])
    }

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

    @Test func removeMarksItRemovedAndKeepsProgress() async throws {
        let library = try await queuedLibrary(2)
        try await library.setProgress(episode(1), to: 300)
        try await library.removeFromQueue(episode(1))
        #expect(try await library.queue() == [episode(2)])
        #expect(try await library.place(of: episode(1)) == .archive(.dismissed))
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
        #expect(try await library.speedOverride(show) == nil)
        try await library.setSpeedOverride(show, to: .normal)
        #expect(try await library.speedOverride(show) == .normal)
        #expect(try await library.effectiveSpeed(for: show) == .normal)
        try await library.setSpeedOverride(show, to: nil)
        #expect(try await library.speedOverride(show) == nil)
        #expect(try await library.effectiveSpeed(for: show) == PlaybackSpeed(1.5))
    }

    @Test func voiceBoostIsOffByDefault() async throws {
        let library = try Library.open(inMemory: true)
        try await library.addSubscription(show, feedURL: feedURL)
        #expect(try await library.globalVoiceBoost() == false)
        #expect(try await library.effectiveVoiceBoost(for: show) == false)
    }

    @Test func showsFollowTheVoiceBoostDefaultUnlessTheyChoose() async throws {
        let library = try Library.open(inMemory: true)
        try await library.addSubscription(show, feedURL: feedURL)
        try await library.setGlobalVoiceBoost(true)
        #expect(try await library.voiceBoostOverride(show) == nil)
        #expect(try await library.effectiveVoiceBoost(for: show) == true)

        try await library.setVoiceBoostOverride(show, to: false)
        #expect(try await library.voiceBoostOverride(show) == false)
        #expect(try await library.effectiveVoiceBoost(for: show) == false)

        try await library.setGlobalVoiceBoost(false)
        try await library.setVoiceBoostOverride(show, to: true)
        #expect(try await library.effectiveVoiceBoost(for: show) == true)

        try await library.setVoiceBoostOverride(show, to: nil)
        #expect(try await library.voiceBoostOverride(show) == nil)
        #expect(try await library.effectiveVoiceBoost(for: show) == false)
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

    @Test func keepsWebPages() async throws {
        let library = try Library.open(inMemory: true)
        try await library.saveFeed(try FeedParser.parse(fixture("own-links.xml")), for: show)
        #expect(try await library.show(show)?.webPage == URL(string: "https://example.com/own"))
        let pages = try await library.episodes(of: show).map(\.webPage)
        #expect(Set(pages) == [URL(string: "https://example.com/own/1"), URL(string: "https://example.com/own/2")])
        let episode = try #require(try await library.episodes(of: show).first)
        #expect(try await library.episode(episode.key)?.webPage == episode.webPage)
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

struct SharedShowTests {
    let memo = URL(string: "casterr-shared:///memo.m4a")!

    @Test func aSharedFilePlaysNext() async throws {
        let library = try Library.open(inMemory: true)
        try await library.addSubscription(show, feedURL: feedURL)
        try await library.saveFeed(try FeedParser.parse(fixture("podcast.xml")), for: show)
        let first = try await library.episodes(of: show)[0].key
        try await library.addToQueue(first)

        let second = try await library.episodes(of: show)[1].key
        try await library.addToQueue(second)
        let key = try await library.addSharedEpisode(id: "1", title: "Voice memo 12", duration: 95, audioURL: memo)
        #expect(try await library.playableQueue() == [first, key, second])
        let episode = try await library.episode(key)
        #expect(episode?.title == "Voice memo 12" && episode?.duration == 95 && episode?.showKey == .shared)
        #expect(try await library.show(.shared)?.title == "Shared with Casterr")
    }

    @Test func listsNewestFirst() async throws {
        let library = try Library.open(inMemory: true)
        await library.useClock { Date(timeIntervalSince1970: 1_000) }
        let older = try await library.addSharedEpisode(id: "1", title: "Older", duration: nil, audioURL: memo)
        await library.useClock { Date(timeIntervalSince1970: 2_000) }
        let newer = try await library.addSharedEpisode(id: "2", title: "Newer", duration: nil, audioURL: URL(string: "casterr-shared:///b.mp3")!)
        #expect(try await library.episodes(of: .shared).map(\.key) == [newer, older])
    }

    @Test func deleteRemovesItFromTheQueueAndTheShow() async throws {
        let library = try Library.open(inMemory: true)
        let a = try await library.addSharedEpisode(id: "1", title: "A", duration: nil, audioURL: memo)
        let b = try await library.addSharedEpisode(id: "2", title: "B", duration: nil, audioURL: URL(string: "casterr-shared:///b.mp3")!)
        try await library.deleteSharedEpisode(a)
        #expect(try await library.queue() == [b])
        #expect(try await library.episodes(of: .shared).map(\.key) == [b])
        try await library.wipeFeedCache()
        #expect(try await library.episodes(of: .shared).map(\.key) == [b])
        #expect(try await library.episode(a) == nil)
    }

    @Test func theBuiltInShowIsNeverASubscription() async throws {
        let library = try Library.open(inMemory: true)
        try await library.addSharedEpisode(id: "1", title: "A", duration: nil, audioURL: memo)
        #expect(try await library.subscriptions().isEmpty)
    }

    @Test func deleteIgnoresEpisodesOfOtherShows() async throws {
        let library = try Library.open(inMemory: true)
        try await library.addSubscription(show, feedURL: feedURL)
        try await library.saveFeed(try FeedParser.parse(fixture("podcast.xml")), for: show)
        let feedEpisode = try await library.episodes(of: show)[0].key
        try await library.deleteSharedEpisode(feedEpisode)
        #expect(try await library.episode(feedEpisode) != nil)
    }
}

struct PlayableQueueTests {
    /// Queue: hidden, a, b, c (hidden is an episode this device doesn't have).
    private func setUp() async throws -> (Library, hidden: EpisodeKey, [EpisodeKey]) {
        let library = try Library.open(inMemory: true)
        try await library.addSubscription(show, feedURL: feedURL)
        try await library.saveFeed(try FeedParser.parse(fixture("podcast.xml")), for: show)
        let keys = Array(try await library.episodes(of: show).map(\.key).prefix(4))
        let hidden = EpisodeKey(rawValue: "casterr:shared|guid:shared-elsewhere")
        try await library.addToQueue(hidden)
        for key in keys.prefix(3) { try await library.addToQueue(key) }
        return (library, hidden, keys)
    }

    @Test func movingCountsOnlyWhatThisDeviceShows() async throws {
        let (library, _, k) = try await setUp()
        try await library.movePlayable(k[2], to: 0)
        #expect(try await library.playableQueue() == [k[2], k[0], k[1]])
        try await library.movePlayable(k[2], to: 2)
        #expect(try await library.playableQueue() == [k[0], k[1], k[2]])
    }

    @Test func playNextLandsAfterTheVisibleNowPlaying() async throws {
        let (library, _, k) = try await setUp()
        try await library.addSharedEpisode(id: "x", title: "X", duration: nil, audioURL: URL(string: "casterr-shared:///x.mp3")!)
        let shared = try #require(try await library.episodes(of: .shared).first?.key)
        #expect(try await library.playableQueue() == [k[0], shared, k[1], k[2]])
    }
}
