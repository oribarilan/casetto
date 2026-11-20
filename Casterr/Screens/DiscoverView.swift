import CasterrCore
import SwiftUI

/// Top shows, or search results while there is a query. Subscribe starts a show at Inbox; Star at Auto-queue.
/// One Cassy at a time: big while loading or failing, otherwise in the card above the list.
struct DiscoverView: View {
    @Environment(AppModel.self) private var model
    let query: String
    /// In onboarding, the cheer also points at Done.
    var inOnboarding = false
    /// Shows you follow that match the search. They come first, and the directory results leave them out.
    var followed: [FollowedShow] = []

    @State private var results: [DirectoryShow] = []
    @State private var levels: [ShowKey: TriageLevel] = [:]
    @State private var working: Set<String> = []
    @State private var message: String?
    @State private var loading = false
    @State private var topShowsFailed = false
    @State private var attempt = 0
    /// The one-time tip on a star, right after the first follow with +.
    @State private var tip: CassyTip?

    private var starred: Bool { levels.values.contains { $0 == .autoQueue || $0 == .playNext } }

    private var directoryResults: [DirectoryShow] {
        let followedKeys = Set(followed.map(\.key))
        return results.filter { show in ShowKey(feedURL: show.feedURL).map { !followedKeys.contains($0) } ?? true }
    }

    var body: some View {
        Group {
            if loading && results.isEmpty {
                VStack(spacing: 10) {
                    CassyView(job: .loading, size: 150)
                    Text("Flipping through the shelves…").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if topShowsFailed && query.isEmpty {
                CassyEmptyState(job: .error, title: "I couldn't load the top shows.",
                                message: "Search still works. Try a show you love.") {
                    Button("Try Again") { attempt += 1 }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if (starred && inOnboarding) || query.isEmpty {
                        Section { cassyCard }
                    }
                    if !followed.isEmpty {
                        Section("Your shows") {
                            ForEach(followed, id: \.key) { show in
                                NavigationLink(value: Route.show(show.key)) {
                                    HStack(spacing: 12) {
                                        ArtworkView(url: show.artworkURL, title: show.title, size: 48)
                                        VStack(alignment: .leading) {
                                            Text(show.title).lineLimit(2)
                                            if let author = show.author {
                                                Text(author).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Section(query.isEmpty ? "Popular now" : followed.isEmpty ? "Results" : "More shows") {
                        if let message {
                            Text(message).foregroundStyle(.secondary)
                        }
                        ForEach(directoryResults, id: \.id) { show in
                            row(show)
                        }
                    }
                }
                .cassyTips($tip)
            }
        }
        .task(id: "\(query)|\(attempt)") { await loadResults() }
        .task(id: model.revision) { await loadLevels() }
    }

    /// Cassy's card: what the list is and how to follow, or a cheer once a show is starred.
    private var cassyCard: some View {
        HStack(spacing: 12) {
            CassyView(job: starred ? .success : .idle, size: 56)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(starred ? "Nice pick!" : "These are popular right now.")
                    .font(.subheadline.weight(.heavy))
                Text(starred
                     ? (inOnboarding ? "I'll queue its new episodes. Keep going, or tap Done." : "I'll queue its new episodes.")
                     : "Tap + to follow any of them, or search for a show you love.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .animation(.spring, value: starred)
    }

    private func row(_ show: DirectoryShow) -> some View {
        let key = ShowKey(feedURL: show.feedURL)
        let level = key.flatMap { levels[$0] }
        let busy = working.contains(show.id)
        return HStack(spacing: 12) {
            ArtworkView(url: show.artworkURL, title: show.title, size: 48)
            VStack(alignment: .leading) {
                Text(show.title).lineLimit(2)
                if let author = show.author {
                    Text(author).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(level == .autoQueue ? "Unstar" : "Star", systemImage: level == .autoQueue ? "star.fill" : "star") {
                // Starring before the tip shows means the listener already knows the star.
                CassyTip.markShown("star")
                tip = nil
                act(show) { try await star(show, level: level) }
            }
            .accessibilityIdentifier("starButton")
            .cassyTipTarget("star.\(show.id)")
            Button(level == nil ? "Subscribe" : "Unsubscribe",
                   systemImage: level == nil ? "plus.circle" : "checkmark.circle.fill") {
                act(show) {
                    try await toggleSubscription(show, level: level)
                    // The first follow with + teaches the star, once.
                    if level == nil, !starred {
                        tip = CassyTip.once("star", target: "star.\(show.id)",
                                            text: "Never miss this one? Star it and I'll queue its new episodes.")
                    }
                }
            }
            .accessibilityIdentifier("subscribeButton")
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .font(.title3)
        .disabled(busy)
        .opacity(busy ? 0.5 : 1)
    }

    private func act(_ show: DirectoryShow, _ work: @escaping () async throws -> Void) {
        working.insert(show.id)
        Task {
            if let error = await model.change(work) { message = error }
            working.remove(show.id)
        }
    }

    /// Starring subscribes at Auto-queue, so the newest episode goes to the Queue. Unstarring returns to Inbox.
    private func star(_ show: DirectoryShow, level: TriageLevel?) async throws {
        guard let key = ShowKey(feedURL: show.feedURL) else { return }
        switch level {
        case nil: _ = try await model.feeds.subscribe(to: show.feedURL, level: .autoQueue)
        case .autoQueue: try await model.library.setLevel(key, to: .inbox)
        default: try await model.library.setLevel(key, to: .autoQueue)
        }
    }

    private func toggleSubscription(_ show: DirectoryShow, level: TriageLevel?) async throws {
        guard let key = ShowKey(feedURL: show.feedURL) else { return }
        if level == nil {
            _ = try await model.feeds.subscribe(to: show.feedURL)
        } else {
            try await model.feeds.unsubscribe(key)
        }
    }

    private func loadResults() async {
        let term = query.trimmingCharacters(in: .whitespaces)
        loading = true
        defer { loading = false }
        do {
            if term.isEmpty {
                results = try await model.directory.topShows()
                topShowsFailed = false
            } else {
                // Wait for typing to pause: the search API allows about 20 calls a minute.
                try await Task.sleep(for: .milliseconds(400))
                results = try await model.directory.search(term)
            }
            message = results.isEmpty && !term.isEmpty ? "No shows found." : nil
        } catch is CancellationError {
        } catch {
            if term.isEmpty { topShowsFailed = true } else { message = "I couldn't search right now. Try again in a moment." }
        }
    }

    private func loadLevels() async {
        let subscriptions = (try? await model.library.subscriptions()) ?? []
        levels = Dictionary(subscriptions.map { ($0.showKey, $0.level) }, uniquingKeysWith: { first, _ in first })
    }
}

/// First launch: top shows and search, closed with Done or Skip.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    let close: () -> Void
    @State private var query = ""
    @State private var following = false

    var body: some View {
        NavigationStack {
            DiscoverView(query: query, inOnboarding: true)
                .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search podcasts")
                .navigationTitle("Find Shows")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    Button(following ? "Done" : "Skip", action: close)
                }
                .task(id: model.revision) {
                    following = !((try? await model.library.subscriptions().isEmpty) ?? true)
                }
        }
    }
}

/// A show you follow, as the search lists it.
struct FollowedShow {
    let key: ShowKey
    let title: String
    let author: String?
    let artworkURL: URL?
}
