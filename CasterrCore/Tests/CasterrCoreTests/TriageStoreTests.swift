import Foundation
import Synchronization
import Testing
@testable import CasterrCore

/// A clock the tests move forward by hand.
private final class TestClock: Sendable {
    private let date = Mutex(Date(timeIntervalSince1970: 1_800_000_000))
    var now: Date { date.withLock { $0 } }
    func advance(days: Double) { date.withLock { $0 += days * 86_400 } }
}

private let showA = ShowKey(feedURL: URL(string: "https://a.example.com/feed")!)!
private let showB = ShowKey(feedURL: URL(string: "https://b.example.com/feed")!)!

/// Episode `n` of a show, published `n` days after a fixed date.
private func episode(_ n: Int, of show: ShowKey = showA) -> EpisodeKey {
    EpisodeKey(show: show, guid: "ep\(n)", audioURL: URL(string: "https://cdn.example.com/\(n).mp3")!)
}

private func feed(_ numbers: ClosedRange<Int>) -> ParsedShow {
    ParsedShow(title: "Show", episodes: numbers.map { n in
        ParsedEpisode(
            guid: "ep\(n)", title: "Episode \(n)", audioURL: URL(string: "https://cdn.example.com/\(n).mp3")!,
            publishDate: Date(timeIntervalSince1970: 1_700_000_000 + Double(n) * 86_400)
        )
    })
}

/// A library subscribed to `show`, whose feed holds episodes 1 to `count`, as `FeedService.subscribe` leaves it.
private func subscribed(
    to shows: [ShowKey] = [showA], episodes count: Int = 3, clock: TestClock = TestClock()
) async throws -> Library {
    let library = try Library.open(inMemory: true)
    await library.useClock { clock.now }
    // These tests are about the mechanics, so they pin a 7-day period rather than the default.
    try await library.setGlobalExpiry(.days(7))
    for show in shows {
        try await library.saveFeed(feed(1...count), for: show)
        try await library.addSubscription(show, feedURL: URL(string: show.rawValue)!)
        try await library.triage(show)
    }
    return library
}

/// The show publishes episode `n` and the app refreshes.
private func release(_ n: Int, of show: ShowKey = showA, in library: Library) async throws {
    try await library.saveFeed(feed(1...n), for: show)
    try await library.triage(show)
}

struct SubscribeTriageTests {
    @Test func subscribingPutsOnlyTheNewestEpisodeInTheInbox() async throws {
        let library = try await subscribed(episodes: 200)
        #expect(try await library.inbox() == [episode(200)])
        #expect(try await library.place(of: episode(199)) == nil)
        #expect(try await library.episodes(of: showA).count == 200)
        #expect(try await library.subscriptions().first?.level == .inbox)
    }

    @Test func subscriptionFromBeforeTriagePlacesNothingOnItsFirstRefresh() async throws {
        let library = try Library.open(inMemory: true)
        try await library.addSubscription(showA, feedURL: URL(string: showA.rawValue)!)
        try await release(5, in: library)
        #expect(try await library.inbox().isEmpty)
        try await release(6, in: library)
        #expect(try await library.inbox() == [episode(6)])
    }
}

struct NewEpisodeTriageTests {
    @Test func autoQueueAppendsToTheQueue() async throws {
        let library = try await subscribed()
        try await library.addToQueue(episode(1))
        try await library.setLevel(showA, to: .autoQueue)
        try await release(4, in: library)
        #expect(try await library.queue() == [episode(1), episode(4)])
        #expect(try await library.lastMove(of: episode(4)) == LastMove(reason: .autoQueued))
    }

    @Test func inboxLevelPutsItInTheInbox() async throws {
        let library = try await subscribed()
        try await release(4, in: library)
        #expect(try await library.inbox() == [episode(4), episode(3)])
        #expect(try await library.lastMove(of: episode(4)) == LastMove(reason: .arrived))
    }

    @Test func skipArchivesIt() async throws {
        let library = try await subscribed()
        try await library.setLevel(showA, to: .skip)
        try await release(4, in: library)
        #expect(try await library.place(of: episode(4)) == .archive(.skipped))
    }

    @Test func severalNewEpisodesArePlacedOldestFirst() async throws {
        let library = try await subscribed()
        try await library.setLevel(showA, to: .autoQueue)
        try await release(6, in: library)
        #expect(try await library.queue() == [episode(4), episode(5), episode(6)])
    }

    @Test func refetchingAfterACacheWipeTriagesNothingTwice() async throws {
        let library = try await subscribed()
        try await library.dismiss(episode(3))
        try await library.wipeFeedCache()
        try await release(3, in: library)
        #expect(try await library.inbox().isEmpty)
        #expect(try await library.place(of: episode(3)) == .archive(.dismissed))
    }

    @Test func episodeTheListenerAlreadyPlacedStaysPut() async throws {
        let library = try await subscribed()
        try await library.addToQueue(episode(4))
        try await release(4, in: library)
        #expect(try await library.place(of: episode(4)) == .queue)
        #expect(try await library.lastMove(of: episode(4))?.reason == .listener)
    }

    @Test func unsubscribedShowIsNotTriaged() async throws {
        let library = try await subscribed()
        try await library.removeSubscription(showA)
        try await release(4, in: library)
        #expect(try await library.place(of: episode(4)) == nil)
    }
}

struct PlayNextTests {
    @Test func releasesStackAfterNowPlayingInReleaseOrder() async throws {
        let library = try await subscribed(to: [showA, showB])
        for n in 1...4 { try await library.addToQueue(episode(n, of: showB)) }
        try await library.setLevel(showA, to: .playNext)
        try await library.setLevel(showB, to: .playNext)
        try await release(4, of: showA, in: library)
        try await release(5, of: showB, in: library)
        #expect(try await library.queue() == [
            episode(1, of: showB), episode(4), episode(5, of: showB),
            episode(2, of: showB), episode(3, of: showB), episode(4, of: showB),
        ])
    }

    @Test func emptyQueueGetsTheEpisodeAsItsOnlyItem() async throws {
        let library = try await subscribed()
        try await library.setLevel(showA, to: .playNext)
        try await release(4, in: library)
        #expect(try await library.queue() == [episode(4)])
    }
}

struct InboxStoreTests {
    @Test func countsAndListsNewestFirst() async throws {
        let library = try await subscribed()
        try await release(5, in: library)
        #expect(try await library.inbox() == [episode(5), episode(4), episode(3)])
        #expect(try await library.inboxCount() == 3)
    }

    @Test func queueingTakesItOutOfTheInboxToTheEnd() async throws {
        let library = try await subscribed()
        try await library.addToQueue(episode(1))
        try await library.addToQueue(episode(3))
        #expect(try await library.inbox().isEmpty)
        #expect(try await library.queue() == [episode(1), episode(3)])
    }

    @Test func listenerPlayNextGoesSecondWithNoLabel() async throws {
        let library = try await subscribed(episodes: 4)
        for n in 1...4 { try await library.addToQueue(episode(n)) }
        try await library.playNextByListener(episode(4))
        #expect(try await library.queue() == [episode(1), episode(4), episode(2), episode(3)])
        #expect(try await library.lastMove(of: episode(4)) == LastMove(reason: .listener))
    }

    @Test func dismissArchivesIt() async throws {
        let library = try await subscribed()
        try await library.dismiss(episode(3))
        #expect(try await library.place(of: episode(3)) == .archive(.dismissed))
        #expect(try await library.lastMove(of: episode(3)) == LastMove(reason: .listener))
    }

    @Test func unsubscribeArchivesInboxEpisodesAndKeepsQueuedOnes() async throws {
        let library = try await subscribed(to: [showA, showB])
        try await release(5, in: library)
        try await library.addToQueue(episode(4))
        try await library.removeSubscription(showA)
        #expect(try await library.inbox() == [episode(3, of: showB)])
        #expect(try await library.place(of: episode(5)) == .archive(.unsubscribed))
        #expect(try await library.queue() == [episode(4)])
    }
}

struct ExpiryStoreTests {
    @Test func defaultPeriodIs14Days() async throws {
        let library = try Library.open(inMemory: true)
        #expect(try await library.globalExpiry() == .days(14))
        #expect(InboxExpiry.choices == [.days(1), .days(3), .days(7), .days(14), .days(30), .never])
    }

    @Test func episodeExpiresAfterTheGlobalPeriod() async throws {
        let clock = TestClock()
        let library = try await subscribed(clock: clock)
        clock.advance(days: 8)
        try await library.expireInbox()
        #expect(try await library.place(of: episode(3)) == .archive(.expired))
        #expect(try await library.lastMove(of: episode(3))?.reason.label == "Removed after 7 days")
    }

    @Test func showOverrideWins() async throws {
        let clock = TestClock()
        let library = try await subscribed(to: [showA, showB], clock: clock)
        try await library.setExpiryOverride(showA, to: .days(14))
        clock.advance(days: 8)
        try await library.expireInbox()
        #expect(try await library.inbox() == [episode(3)])
        clock.advance(days: 6)
        try await library.expireInbox()
        #expect(try await library.lastMove(of: episode(3))?.reason == .expired(days: 14))
    }

    @Test func daysLeftCountDownAndSkipNever() async throws {
        let clock = TestClock()
        let library = try await subscribed(to: [showA, showB], clock: clock)
        try await library.setExpiryOverride(showB, to: .never)
        #expect(try await library.inboxDaysLeft() == [episode(3): 7])
        clock.advance(days: 4.5)
        #expect(try await library.inboxDaysLeft() == [episode(3): 3])
        clock.advance(days: 2.2)
        #expect(try await library.inboxDaysLeft() == [episode(3): 1])
    }

    @Test func neverKeepsInboxEpisodes() async throws {
        let clock = TestClock()
        let library = try await subscribed(clock: clock)
        try await library.setExpiryOverride(showA, to: .never)
        clock.advance(days: 365)
        try await library.expireInbox()
        #expect(try await library.inbox() == [episode(3)])
    }

    @Test func globalSettingChanges() async throws {
        let clock = TestClock()
        let library = try await subscribed(clock: clock)
        try await library.setGlobalExpiry(.days(3))
        clock.advance(days: 3)
        try await library.expireInbox()
        #expect(try await library.inbox().isEmpty)
    }

    @Test func clearingTheOverrideFollowsTheGlobalSetting() async throws {
        let library = try await subscribed()
        try await library.setExpiryOverride(showA, to: .never)
        try await library.setExpiryOverride(showA, to: nil)
        #expect(try await library.subscriptions().first?.expiryOverride == nil)
    }
}

struct MoveRecordTests {
    @Test func listenerActionsRecordListenerMoves() async throws {
        let clock = TestClock()
        let library = try await subscribed(clock: clock)
        try await library.addToQueue(episode(1))
        try await library.markPlayed(episode(2))
        for key in [episode(1), episode(2)] {
            #expect(try await library.lastMove(of: key) == LastMove(reason: .listener))
        }
    }

    @Test func untouchedEpisodeHasNoMove() async throws {
        let library = try await subscribed()
        #expect(try await library.lastMove(of: episode(1)) == nil)
    }
}

struct StarStoreTests {
    private func level(_ library: Library) async throws -> (TriageLevel, Bool)? {
        try await library.subscriptions().first.map { ($0.level, $0.starred) }
    }

    @Test func newSubscriptionIsNotStarred() async throws {
        let library = try await subscribed()
        #expect(try await level(library)! == (.inbox, false))
    }

    @Test func starringAnInboxShowQueuesItsNewEpisodes() async throws {
        let library = try await subscribed()
        try await library.setStarred(showA, true)
        #expect(try await level(library)! == (.autoQueue, true))
    }

    @Test(arguments: [TriageLevel.playNext, .skip])
    func starringKeepsOtherSettings(level start: TriageLevel) async throws {
        let library = try await subscribed()
        try await library.setLevel(showA, to: start)
        try await library.setStarred(showA, true)
        #expect(try await level(library)! == (start, true))
    }

    @Test func aStarredShowKeepsItsStarWhenTheSettingChanges() async throws {
        let library = try await subscribed()
        try await library.setStarred(showA, true)
        try await library.setLevel(showA, to: .inbox)
        #expect(try await level(library)! == (.inbox, true))
    }

    @Test func unstarringKeepsTheSetting() async throws {
        let library = try await subscribed()
        try await library.setStarred(showA, true)
        try await library.setStarred(showA, false)
        #expect(try await level(library)! == (.autoQueue, false))
    }
}
