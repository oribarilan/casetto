import Foundation
import Synchronization
import Testing

@testable import CasterrCore

private let start = Date(timeIntervalSince1970: 1_800_000_000)
private var now: Date { start }
private let day: TimeInterval = 86_400

/// An episode released `daysAgo` days before `now`, first played `playedAfter` days after release.
private func episode(_ daysAgo: Double, playedAfter: Double? = nil, place: Place? = nil) -> RuleCard.Episode {
    let published = now.addingTimeInterval(-daysAgo * day)
    return RuleCard.Episode(
        published: published, firstPlayedAt: playedAfter.map { published.addingTimeInterval($0 * day) }, place: place)
}

private func evaluate(_ episodes: [RuleCard.Episode]) -> RuleCard.Kind? {
    RuleCard.evaluate(episodes: episodes, now: now, thresholds: .init())
}

struct RuleCardEvaluationTests {
    @Test func fourQuickPlaysEarnAutoQueue() {
        #expect(evaluate((2...5).map { episode(Double($0) * 7, playedAfter: 0.5) }) == .autoQueue)
    }

    @Test func oneLatePlayEarnsNothing() {
        var episodes = (2...5).map { episode(Double($0) * 7, playedAfter: 0.5) }
        episodes[2] = episode(21, playedAfter: 2)
        #expect(evaluate(episodes) == nil)
    }

    @Test func releaseFromTheLastDayIsNotCountedYet() {
        let episodes = [episode(0.2)] + (1...4).map { episode(Double($0) * 7, playedAfter: 0.1) }
        #expect(evaluate(episodes) == .autoQueue)
    }

    @Test func tooFewEpisodesEarnNothing() {
        #expect(evaluate((1...3).map { episode(Double($0) * 7, playedAfter: 0.1) }) == nil)
        #expect(evaluate((1...2).map { episode(Double($0) * 7, place: .archive(.expired)) }) == nil)
    }

    @Test func threeExpiriesEarnIgnored() {
        let episodes =
            (1...3).map { episode(Double($0) * 7, place: .archive(.expired)) } + [episode(28, playedAfter: 0.1)]
        #expect(evaluate(episodes) == .ignored)
    }

    @Test func aDismissalAmongTheNewestBreaksIgnored() {
        let episodes = [
            episode(7, place: .archive(.expired)), episode(14, place: .archive(.dismissed)),
            episode(21, place: .archive(.expired)),
        ]
        #expect(evaluate(episodes) == nil)
    }

    @Test func ignoredWinsOverAutoQueue() {
        let episodes =
            (1...3).map { episode(Double($0) * 7, playedAfter: 0.1, place: .archive(.expired)) }
            + [episode(28, playedAfter: 0.1)]
        #expect(evaluate(episodes) == .ignored)
    }
}

/// A clock the tests move forward by hand.
private final class TestClock: Sendable {
    private let date = Mutex(start)
    var now: Date { date.withLock { $0 } }
    func advance(days: Double) { date.withLock { $0 += days * day } }
}

private let show = ShowKey(feedURL: URL(string: "https://example.com/feed")!)!

private func key(_ n: Int) -> EpisodeKey {
    EpisodeKey(show: show, guid: "ep\(n)", audioURL: URL(string: "https://cdn.example.com/\(n).mp3")!)
}

private func released(_ n: Int) -> Date {
    now.addingTimeInterval(-Double(6 - n) * 7 * day - 3 * day)
}

private func feed(_ numbers: ClosedRange<Int>) -> ParsedShow {
    ParsedShow(
        title: "Show",
        episodes: numbers.map { n in
            ParsedEpisode(
                guid: "ep\(n)", title: "Episode \(n)", audioURL: URL(string: "https://cdn.example.com/\(n).mp3")!,
                publishDate: released(n))
        })
}

/// A library subscribed to a weekly show at the Inbox level. Episode 3 arrived on subscribe and
/// episodes 4 to 6 on a later refresh, so episodes 3 to 6 are in the Inbox. Episode 6 is 3 days old.
private func library(clock: TestClock) async throws -> Library {
    let library = try Library.open(inMemory: true)
    await library.useClock { clock.now }
    try await library.setGlobalExpiry(.days(7))
    try await library.saveFeed(feed(1...3), for: show)
    try await library.addSubscription(show, feedURL: URL(string: show.rawValue)!)
    try await library.triage(show)
    try await library.saveFeed(feed(1...6), for: show)
    try await library.triage(show)
    return library
}

/// Lets the Inbox episodes expire.
private func expireInbox(_ library: Library, clock: TestClock) async throws {
    clock.advance(days: 8)
    try await library.expireInbox()
}

struct RuleCardStoreTests {
    @Test func quickPlaysRaiseTheAutoQueueCardAndAcceptingClearsIt() async throws {
        let clock = TestClock()
        let library = try await library(clock: clock)
        // Each play happened half a day after release: set the clock back to then.
        for n in 3...6 {
            let playedAt = released(n).addingTimeInterval(day / 2)
            await library.useClock { playedAt }
            try await library.recordPlayStart(key(n))
        }
        await library.useClock { clock.now }
        #expect(try await library.ruleCards() == [RuleCard(show: show, kind: .autoQueue)])
        // Replaying later keeps the first start, so the card stays.
        try await library.recordPlayStart(key(6))
        #expect(try await library.ruleCards() == [RuleCard(show: show, kind: .autoQueue)])
        try await library.setLevel(show, to: .autoQueue)
        #expect(try await library.ruleCards().isEmpty)
    }

    @Test func expiriesRaiseTheIgnoredCard() async throws {
        let clock = TestClock()
        let library = try await library(clock: clock)
        #expect(try await library.ruleCards().isEmpty)
        try await expireInbox(library, clock: clock)
        #expect(try await library.ruleCards() == [RuleCard(show: show, kind: .ignored)])
        try await library.setLevel(show, to: .skip)
        #expect(try await library.ruleCards().isEmpty)
    }

    @Test func notNowHidesFor30Days() async throws {
        let clock = TestClock()
        let library = try await library(clock: clock)
        try await expireInbox(library, clock: clock)
        try await library.hideRuleCard(RuleCard(show: show, kind: .ignored), forever: false)
        #expect(try await library.ruleCards().isEmpty)
        clock.advance(days: 29)
        #expect(try await library.ruleCards().isEmpty)
        clock.advance(days: 1.1)
        #expect(try await library.ruleCards() == [RuleCard(show: show, kind: .ignored)])
    }

    @Test func neverHidesForGood() async throws {
        let clock = TestClock()
        let library = try await library(clock: clock)
        try await expireInbox(library, clock: clock)
        try await library.hideRuleCard(RuleCard(show: show, kind: .ignored), forever: true)
        clock.advance(days: 3650)
        #expect(try await library.ruleCards().isEmpty)
    }

    @Test func thresholdsCanBeReplaced() async throws {
        let clock = TestClock()
        let library = try await library(clock: clock)
        await library.useRuleThresholds(.init(autoQueue: 4, ignored: 1))
        try await library.dismiss(key(5))
        try await library.dismiss(key(4))
        #expect(try await library.ruleCards().isEmpty)
        try await expireInbox(library, clock: clock)
        #expect(try await library.ruleCards() == [RuleCard(show: show, kind: .ignored)])
    }

    @Test func otherLevelsShowNoCard() async throws {
        let clock = TestClock()
        let library = try await library(clock: clock)
        try await expireInbox(library, clock: clock)
        try await library.setLevel(show, to: .playNext)
        #expect(try await library.ruleCards().isEmpty)
    }
}
