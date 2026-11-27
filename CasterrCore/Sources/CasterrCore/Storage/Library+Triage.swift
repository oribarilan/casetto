import Foundation
import SwiftData

extension Library {
    // MARK: Triage

    /// Places the show's new episodes by its level, oldest first. New means published after
    /// the subscription's triage date and never placed. Undated episodes are never new.
    /// The first triage of a subscription from before triage existed places nothing.
    @discardableResult
    public func triage(_ showKey: ShowKey) throws -> RefreshSummary {
        guard let subscription = try subscription(showKey) else { return RefreshSummary() }
        let records = try episodeRecords(of: showKey)
        guard let after = subscription.triageAfter else {
            subscription.triageAfter = records.compactMap(\.publishDate).max() ?? clock()
            try modelContext.save()
            return RefreshSummary()
        }
        let destination = (TriageLevel(rawValue: subscription.level) ?? .inbox).destination
        let fresh =
            records
            .compactMap { record in record.publishDate.map { (key: EpisodeKey(rawValue: record.key), date: $0) } }
            .filter { $0.date > after }
            .sorted { $0.date < $1.date }
        var summary = RefreshSummary()
        for episode in fresh where try state(episode.key) == nil {
            try relocate(state(episode.key, creating: true)!, to: destination.place, reason: destination.reason)
            switch destination.place {
            case .inbox: summary.arrived += 1
            case .queue: summary.queued += 1
            case .archive: summary.skipped += 1
            }
        }
        try modelContext.save()
        return summary
    }

    // MARK: Rule cards

    /// Cards for Inbox-level shows whose card isn't hidden, in subscription order.
    public func ruleCards() throws -> [RuleCard] {
        let now = clock()
        let states = Dictionary(
            try modelContext.fetch(FetchDescriptor<EpisodeState>()).map { ($0.episodeKey, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        var cards: [RuleCard] = []
        for subscription in try modelContext.fetch(
            FetchDescriptor<Subscription>(sortBy: [SortDescriptor(\.subscribedAt)]))
        where subscription.level == TriageLevel.inbox.rawValue {
            let show = ShowKey(rawValue: subscription.showKey)
            var episodes: [RuleCard.Episode] = []
            for record in try episodeRecords(of: show) {
                guard let published = record.publishDate else { continue }
                let state = states[record.key]
                episodes.append(
                    RuleCard.Episode(
                        published: published, firstPlayedAt: state?.firstPlayedAt,
                        place: try state.flatMap { try Place(storedPlace: $0.place, archiveReason: $0.archiveReason) }
                    ))
            }
            guard let kind = RuleCard.evaluate(episodes: episodes, now: now, thresholds: ruleThresholds) else {
                continue
            }
            let hiddenUntil =
                kind == .autoQueue ? subscription.autoQueueCardHiddenUntil : subscription.ignoredCardHiddenUntil
            if hiddenUntil.map({ $0 > now }) ?? false { continue }
            cards.append(RuleCard(show: show, kind: kind))
        }
        return cards
    }

    /// Not now hides the card for 30 days; never hides it for good.
    public func hideRuleCard(_ card: RuleCard, forever: Bool) throws {
        guard let subscription = try subscription(card.show) else { return }
        let until = forever ? Date.distantFuture : clock().addingTimeInterval(RuleCard.hideForNotNow)
        switch card.kind {
        case .autoQueue: subscription.autoQueueCardHiddenUntil = until
        case .ignored: subscription.ignoredCardHiddenUntil = until
        }
        try modelContext.save()
    }

    // MARK: Inbox

    /// Newest first.
    public func inbox() throws -> [EpisodeKey] {
        var dated: [(key: EpisodeKey, date: Date)] = []
        for state in try states(in: .inbox) {
            let key = EpisodeKey(rawValue: state.episodeKey)
            dated.append((key, try episodeRecord(key)?.publishDate ?? .distantPast))
        }
        return dated.sorted { $0.date > $1.date }.map(\.key)
    }

    public func inboxCount() throws -> Int {
        try states(in: .inbox).count
    }

    public func dismiss(_ key: EpisodeKey) throws {
        try relocate(state(key, creating: true)!, to: .archive(.dismissed), reason: .listener)
        try modelContext.save()
    }

    /// Whole days until each Inbox episode leaves, rounded up. Episodes whose period is never are left out.
    public func inboxDaysLeft() throws -> [EpisodeKey: Int] {
        let global = InboxExpiry(storedDays: try settings().expiryDays)
        let overrides = try modelContext.fetch(FetchDescriptor<Subscription>()).compactMap { record in
            record.expiryDaysOverride.map {
                (show: ShowKey(rawValue: record.showKey), expiry: InboxExpiry(storedDays: $0))
            }
        }
        let now = clock()
        var left: [EpisodeKey: Int] = [:]
        for state in try states(in: .inbox) {
            let key = EpisodeKey(rawValue: state.episodeKey)
            let expiry = overrides.first { key.belongs(to: $0.show) }?.expiry ?? global
            guard case .days(let days) = expiry, let enteredAt = state.movedAt else { continue }
            let remaining = Double(days) * 86_400 - now.timeIntervalSince(enteredAt)
            left[key] = max(0, Int((remaining / 86_400).rounded(.up)))
        }
        return left
    }

    /// Moves Inbox episodes that waited their show's period, or the global one, to the archive.
    /// Returns how many expired.
    @discardableResult
    public func expireInbox() throws -> Int {
        let global = InboxExpiry(storedDays: try settings().expiryDays)
        let overrides = try modelContext.fetch(FetchDescriptor<Subscription>()).compactMap { record in
            record.expiryDaysOverride.map {
                (show: ShowKey(rawValue: record.showKey), expiry: InboxExpiry(storedDays: $0))
            }
        }
        let now = clock()
        var expired = 0
        for state in try states(in: .inbox) {
            let key = EpisodeKey(rawValue: state.episodeKey)
            let expiry = overrides.first { key.belongs(to: $0.show) }?.expiry ?? global
            guard case .days(let days) = expiry, let enteredAt = state.movedAt,
                expiry.hasExpired(enteredAt: enteredAt, now: now)
            else { continue }
            try relocate(state, to: .archive(.expired), reason: .expired(days: days))
            expired += 1
        }
        try modelContext.save()
        return expired
    }
}
