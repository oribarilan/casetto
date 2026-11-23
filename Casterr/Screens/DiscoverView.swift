import CasterrCore
import SwiftUI

/// Top shows, or search results while there is a query. Subscribe starts a show at Inbox; Star at Auto-queue.
/// One Cassy at a time: big while loading or failing, otherwise in the card above the list.
struct DiscoverView: View {
    @Environment(AppModel.self) private var model
    let query: String
    /// In onboarding, the cheer also points at Done.
    var inOnboarding = false

    @State private var results: [DirectoryShow] = []
    @State private var levels: [ShowKey: TriageLevel] = [:]
    @State private var working: Set<String> = []
    @State private var message: String?
    @State private var loading = false
    @State private var topShowsFailed = false
    @State private var attempt = 0
    /// The other chart (region or United States) is fetched once per visit, so switching is instant.
    @State private var fetchedOtherChart = false
    /// "us" once the listener picks the United States chart; empty follows the phone's region. Kept on this device.
    @AppStorage("chartCountry") private var chosenCountry = ""
    /// The one-time tip on a star, right after the first follow with +.
    @State private var tip: CassyTip?

    /// Shows already starred when this visit began. Only a star given during the visit makes Cassy cheer.
    @State private var starredBefore: Set<ShowKey>?

    private var anyStarred: Bool { levels.values.contains(where: Self.isStar) }
    private var starred: Bool {
        levels.contains { Self.isStar($0.value) && starredBefore?.contains($0.key) == false }
    }
    private static func isStar(_ level: TriageLevel) -> Bool { level == .autoQueue || level == .playNext }

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
                        .filledButton()
                        .buttonBorderShape(.capsule)
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if (starred && inOnboarding) || query.isEmpty {
                        Section { cassyCard }
                    }
                    Section {
                        if let message {
                            Text(message).foregroundStyle(.secondary)
                        }
                        ForEach(results, id: \.id) { show in
                            row(show)
                        }
                    } header: {
                        if query.isEmpty { popularHeading } else { Text("Results") }
                    }
                }
                .cassyTips($tip)
            }
        }
        .task(id: "\(query)|\(attempt)|\(country)") { await loadResults() }
        .task(id: model.revision) { await loadLevels() }
    }

    /// The chart and search country: the listener's pick, or the phone's region.
    private var country: String { chosenCountry.isEmpty ? AppleDirectory.deviceCountry : chosenCountry }

    /// "Popular now · Israel". Outside the United States it's a menu to switch to the United States chart and back.
    @ViewBuilder private var popularHeading: some View {
        let name = Locale.current.region.flatMap { _ in Locale.current.localizedString(forRegionCode: country.uppercased()) }
        let title = name.map { "Popular now · \($0)" } ?? "Popular now"
        if let region = Locale.current.region?.identifier, region != "US",
           let regionName = Locale.current.localizedString(forRegionCode: region),
           let us = Locale.current.localizedString(forRegionCode: "US") {
            Menu {
                Picker("Chart", selection: $chosenCountry) {
                    Text(regionName).tag("")
                    Text(us).tag("us")
                }
            } label: {
                HStack(spacing: 4) {
                    Text(title).foregroundStyle(Color(.secondaryLabel))
                    Image(systemName: "chevron.down").font(.caption.weight(.semibold))
                }
            }
            .accessibilityIdentifier("chartCountry")
        } else {
            Text(title)
        }
    }

    /// Cassy's card: an invitation to add shows, or a cheer once a show is starred.
    private var cassyCard: some View {
        HStack(spacing: 12) {
            CassyView(job: starred ? .success : .idle, size: 56)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(starred ? "Nice pick!" : "Let's add some shows!")
                    .font(.subheadline.weight(.heavy))
                Text(starred
                     ? (inOnboarding ? "I'll queue its new episodes. Keep going, or tap Done." : "I'll queue its new episodes.")
                     : "Tap + to follow one, or search for a show you love.")
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
            // The art and title open the show's page; the star and + act in place.
            NavigationLink(value: Route.directoryShow(show.feedURL)) {
                HStack(spacing: 12) {
                    ArtworkView(url: show.artworkURL, title: show.title, size: 48)
                    VStack(alignment: .leading) {
                        Text(show.title).lineLimit(2)
                        if let author = show.author {
                            Text(author).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(.rect)
            }
            .foregroundStyle(.primary)
            .accessibilityIdentifier("directoryShow")
            Button(level == .autoQueue ? "Unstar" : "Star", systemImage: level == .autoQueue ? "star.fill" : "star") {
                // Starring before the tip shows means the listener already knows the star.
                CassyTip.markShown("star")
                tip = nil
                act(show) { try await star(show, level: level) }
            }
            .accessibilityIdentifier("starButton")
            .cassyTipTarget("star.\(show.id)")
            Button(level == nil ? "Follow" : "Unfollow",
                   systemImage: level == nil ? "plus.circle" : "checkmark.circle.fill") {
                act(show) {
                    try await toggleSubscription(show, level: level)
                    // The first follow with + teaches the star, once.
                    if level == nil, !anyStarred {
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
        if term.isEmpty {
            // The saved list shows at once; with none, the loading Cassy shows until the chart arrives.
            results = model.savedCharts.shows(for: country) ?? []
            topShowsFailed = false
            message = nil
        }
        loading = true
        defer { loading = false }
        do {
            if term.isEmpty {
                results = try await chart(country)
                await fetchOtherChart()
            } else {
                // Wait for typing to pause: the search API allows about 20 calls a minute.
                try await Task.sleep(for: .milliseconds(400))
                results = try await model.directory.search(term, country: country)
            }
            message = results.isEmpty && !term.isEmpty ? "No shows found." : nil
        } catch is CancellationError {
        } catch {
            // A saved list stays when the fresh chart fails.
            if term.isEmpty { topShowsFailed = results.isEmpty } else { message = "I couldn't search right now. Try again in a moment." }
        }
    }

    /// Fetches a chart, saves it, and keeps its art.
    private func chart(_ country: String) async throws -> [DirectoryShow] {
        let shows = try await model.directory.topShows(country: country)
        model.savedCharts.save(shows, for: country)
        ArtCache.keep(shows.compactMap(\.artworkURL))
        return shows
    }

    private func fetchOtherChart() async {
        let other = country == "us" ? AppleDirectory.deviceCountry : "us"
        guard !fetchedOtherChart, other != country else { return }
        fetchedOtherChart = true
        _ = try? await chart(other)
    }

    private func loadLevels() async {
        let subscriptions = (try? await model.library.subscriptions()) ?? []
        levels = Dictionary(subscriptions.map { ($0.showKey, $0.level) }, uniquingKeysWith: { first, _ in first })
        if starredBefore == nil {
            starredBefore = Set(levels.filter { Self.isStar($0.value) }.keys)
        }
    }
}

/// First launch: the welcome screen, then Find Shows.
struct OnboardingView: View {
    let close: () -> Void
    @State private var welcomed = false

    var body: some View {
        if welcomed {
            FindShowsView(inOnboarding: true, close: close)
        } else {
            WelcomeView { withAnimation { welcomed = true } }
        }
    }
}

/// Top shows and search with a large title. Onboarding closes it with Skip until a show is followed, then Done;
/// the Shows tab's + menu opens it as a sheet closed with Done.
struct FindShowsView: View {
    @Environment(AppModel.self) private var model
    var inOnboarding = false
    let close: () -> Void
    @State private var query = ""
    @State private var following = false

    var body: some View {
        NavigationStack {
            DiscoverView(query: query, inOnboarding: inOnboarding)
                .routes()
                .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search podcasts")
                .navigationTitle("Find Shows")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    Button(following || !inOnboarding ? "Done" : "Skip", action: close)
                }
                .task(id: model.revision) {
                    following = !((try? await model.library.subscriptions().isEmpty) ?? true)
                }
        }
    }
}
