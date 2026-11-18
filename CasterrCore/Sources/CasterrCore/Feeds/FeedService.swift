import Foundation

public enum SubscribeError: Error, Equatable {
    /// Not an http or https URL.
    case invalidURL
    /// The URL doesn't return a parsable feed with audio episodes.
    case notAPodcast
    /// A network or server error.
    case unreachable
}

public enum SubscribeOutcome: Equatable, Sendable {
    case subscribed(ShowKey)
    case alreadySubscribed(ShowKey)
}

public struct OPMLImportReport: Equatable, Sendable {
    public struct Failure: Equatable, Sendable {
        public var title: String?
        public var url: String?
        public var reason: String
    }

    public var subscribed: [ShowKey] = []
    public var alreadySubscribed: [ShowKey] = []
    public var failures: [Failure] = []
}

/// Subscribing, importing, refreshing and unsubscribing: the feed side of `Library`.
public struct FeedService: Sendable {
    static let maxConcurrentFetches = 6

    let library: Library
    let fetcher: FeedFetcher

    public init(library: Library, fetcher: FeedFetcher = FeedFetcher()) {
        self.library = library
        self.fetcher = fetcher
    }

    /// Fetches and parses the feed before subscribing. Puts no episode in the Queue.
    public func subscribe(to url: URL) async throws -> SubscribeOutcome {
        guard let key = ShowKey(feedURL: url) else { throw SubscribeError.invalidURL }
        if try await library.isSubscribed(key) { return .alreadySubscribed(key) }

        let feed = try await fetchAndParse(url)
        try await library.saveFeed(feed, for: key)
        try await library.addSubscription(key, feedURL: url)
        return .subscribed(key)
    }

    /// Subscribes to every feed in the file. One bad feed doesn't stop the others.
    public func importOPML(_ data: Data) async throws -> OPMLImportReport {
        let opml = try OPMLParser.parse(data)
        var report = OPMLImportReport()
        report.failures = opml.invalidEntries.map { .init(title: $0.title, url: nil, reason: Self.describe($0.reason)) }

        let results = await forEach(opml.feeds) { feed -> (OPMLFeed, Result<SubscribeOutcome, any Error>) in
            do {
                return (feed, .success(try await subscribe(to: feed.url)))
            } catch {
                return (feed, .failure(error))
            }
        }
        for (feed, result) in results {
            switch result {
            case .success(.subscribed(let key)): report.subscribed.append(key)
            case .success(.alreadySubscribed(let key)): report.alreadySubscribed.append(key)
            case .failure(let error):
                report.failures.append(.init(title: feed.title, url: feed.url.absoluteString, reason: Self.describe(error)))
            }
        }
        return report
    }

    /// Refreshes every subscribed feed. A failing feed records its error and doesn't stop the others.
    public func refreshAll() async throws {
        let subscriptions = try await library.subscriptions()
        _ = await forEach(subscriptions) { subscription in
            await refresh(subscription)
        }
    }

    /// Queued episodes stay in the Queue; the feed is no longer refreshed.
    public func unsubscribe(_ key: ShowKey) async throws {
        try await library.removeSubscription(key)
    }

    private func refresh(_ subscription: SubscriptionInfo) async {
        do {
            let feed = try await fetchAndParse(subscription.feedURL)
            try await library.saveFeed(feed, for: subscription.showKey)
            if let moved = feed.newFeedURL, moved != subscription.feedURL, ShowKey(feedURL: moved) != nil {
                try await library.updateFeedURL(subscription.showKey, to: moved)
            }
        } catch {
            try? await library.recordRefreshFailure(subscription.showKey, error: Self.describe(error))
        }
    }

    private func fetchAndParse(_ url: URL) async throws -> ParsedShow {
        let data: Data
        do {
            data = try await fetcher.fetch(url)
        } catch {
            throw SubscribeError.unreachable
        }
        do {
            return try FeedParser.parse(data)
        } catch {
            throw SubscribeError.notAPodcast
        }
    }

    /// Runs `work` for each item with at most `maxConcurrentFetches` at a time.
    private func forEach<Item: Sendable, Output: Sendable>(
        _ items: [Item], _ work: @escaping @Sendable (Item) async -> Output
    ) async -> [Output] {
        await withTaskGroup(of: Output.self) { group in
            var outputs: [Output] = []
            for (index, item) in items.enumerated() {
                if index >= Self.maxConcurrentFetches, let output = await group.next() {
                    outputs.append(output)
                }
                group.addTask { await work(item) }
            }
            for await output in group { outputs.append(output) }
            return outputs
        }
    }

    static func describe(_ error: any Error) -> String {
        switch error {
        case SubscribeError.invalidURL: "Not a web address"
        case SubscribeError.notAPodcast: "Not a podcast feed"
        case SubscribeError.unreachable: "Couldn't reach the feed"
        default: error.localizedDescription
        }
    }

    static func describe(_ reason: OPMLInvalidEntry.Reason) -> String {
        switch reason {
        case .missingURL: "No feed address"
        case .invalidURL: "Not a web address"
        }
    }
}
