import CasterrCore
import SwiftUI

/// One show: a header with its description, Follow and Star, what happens to new episodes, the episodes left to hear,
/// played episodes folded away, refresh status, and speed override.
struct ShowView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let showKey: ShowKey
    /// For a show opened from Find Shows: where to fetch its feed when the device doesn't have it.
    var feedURL: URL?

    @State private var show: ShowInfo?
    @State private var episodes: [EpisodeInfo] = []
    @State private var places: [EpisodeKey: Place] = [:]
    @State private var moves: [EpisodeKey: LastMove] = [:]
    @State private var subscription: SubscriptionInfo?
    @State private var globalExpiry: InboxExpiry = .standard
    @State private var confirmingUnfollow = false
    @State private var editingNewEpisodes = false
    @State private var showingPlayed = false
    @State private var fullDescription = false
    /// Where an unfollowed show's feed came from, for Follow.
    @State private var cachedFeedURL: URL?
    /// Following, unfollowing, or starring is under way.
    @State private var working = false
    /// Fetching the feed of a show opened from Find Shows.
    @State private var fetchingFeed = false
    /// The show's art, for the share sheet's preview.
    @State private var showArt: UIImage?
    @State private var progress: [EpisodeKey: TimeInterval] = [:]
    /// The Queue's first two episodes, where Play Next would change nothing.
    @State private var queueTop: [EpisodeKey] = []
    /// The row whose action line is open.
    @State private var openRow: EpisodeKey?

    /// The built-in show for files shared to Casterr: Delete instead of following.
    private var isShared: Bool { showKey == .shared }

    var body: some View {
        List {
            header
            followButtons
            if fetchingFeed && episodes.isEmpty {
                Section { ProgressView("Loading episodes…").frame(maxWidth: .infinity) }
            }
            Section {
                failingFeed
                if let speedOverride = subscription?.speedOverride {
                    LabeledContent("Speed (this show)") {
                        HStack {
                            Text(speedOverride.title)
                            Button("Reset") {
                                Task { await model.change { try await model.library.setSpeedOverride(showKey, to: nil) } }
                            }
                        }
                    }
                }
            }
            newEpisodesRow
            // Played episodes fold into one row above the list, so it stays one tap away
            // even when a show's back catalog runs to hundreds of episodes.
            let played = episodes.filter { places[$0.key] == .archive(.played) }
            if !played.isEmpty {
                Section {
                    DisclosureGroup(isExpanded: $showingPlayed) {
                        ForEach(played, id: \.key) { episodeRow($0) }
                    } label: {
                        HStack {
                            Text("Played")
                            Spacer()
                            Text("\(played.count)").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Episodes") {
                ForEach(episodes.filter { places[$0.key] != .archive(.played) }, id: \.key) { episodeRow($0) }
            }
        }
        .keepsRowSwipes()
        // The header names the show, so the bar doesn't repeat it.
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editingNewEpisodes) {
            if let subscription {
                NewEpisodesSheet(showKey: showKey, level: subscription.level,
                                 override: subscription.expiryOverride, global: globalExpiry)
            }
        }
        .toolbar {
            if let show, !isShared, let feedURL = subscription?.feedURL ?? cachedFeedURL {
                ArtShareLink(share: ShareText.show(show, feedURL: feedURL), art: showArt) {
                    Label("Share Show", systemImage: "square.and.arrow.up")
                }
            }
        }
        .confirmationDialog("Unfollow this show?", isPresented: $confirmingUnfollow) {
            Button("Unfollow", role: .destructive) { unfollow() }
        } message: {
            Text("Episodes you queued stay in your Queue.")
        }
        .refreshable { await model.refresh() }
        .task(id: model.revision) { await load() }
        .task { await fetchFeedIfMissing() }
    }

    /// Follow or Following, and Star or Starred, as in Find Shows. The star is a favorite, separate from the level.
    @ViewBuilder private var followButtons: some View {
        if !isShared, let url = subscription?.feedURL ?? cachedFeedURL ?? feedURL {
            let starred = subscription?.starred == true
            HStack(spacing: 10) {
                ShowPageButton(title: subscription == nil ? "Follow" : "Following",
                               symbol: subscription == nil ? "plus" : "checkmark", on: subscription != nil) {
                    if subscription == nil { act { _ = try await model.feeds.subscribe(to: url) } } else { confirmingUnfollow = true }
                }
                .accessibilityIdentifier("followShow")
                ShowPageButton(title: starred ? "Starred" : "Star", symbol: starred ? "star.fill" : "star", on: starred) {
                    act {
                        if subscription == nil { _ = try await model.feeds.subscribe(to: url, level: .autoQueue) }
                        try await model.library.setStarred(showKey, !starred)
                    }
                }
                .accessibilityIdentifier("starShow")
            }
            .disabled(working)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
        }
    }

    private func act(_ work: @escaping () async throws -> Void) {
        working = true
        Task {
            await model.change(work)
            working = false
        }
    }

    /// Unfollows but keeps the feed address, so the page can offer Follow again.
    private func unfollow() {
        guard let url = subscription?.feedURL else { return }
        act {
            try await model.feeds.unsubscribe(showKey)
            try await model.library.setFeedURL(url, for: showKey)
        }
    }

    private func fetchFeedIfMissing() async {
        guard let feedURL, (try? await model.library.show(showKey)) == nil else { return }
        fetchingFeed = true
        await model.change { _ = try await model.feeds.preview(feedURL) }
        fetchingFeed = false
    }

    /// Reads everything first and sets it together, so the page appears whole instead of filling in.
    private func load() async {
        let library = model.library
        let loadedShow = try? await library.show(showKey)
        let loadedEpisodes = (try? await library.episodes(of: showKey)) ?? []
        let keys = loadedEpisodes.map(\.key)
        // One read for every episode: a long back catalog would otherwise hold the page back.
        let snapshots = (try? await library.snapshots(of: keys)) ?? [:]
        let loadedPlaces = snapshots.compactMapValues(\.place)
        let loadedMoves = snapshots.compactMapValues(\.move)
        let loadedProgress = snapshots.compactMapValues { $0.progress > 0 ? $0.progress : nil }
        let loadedQueueTop = Array(((try? await library.playableQueue()) ?? []).prefix(2))
        let loadedSubscription = try? await library.subscriptions().first { $0.showKey == showKey }
        let loadedFeedURL = try? await library.cachedFeedURL(of: showKey)
        let loadedExpiry = (try? await library.globalExpiry()) ?? .standard

        show = loadedShow
        episodes = loadedEpisodes
        places = loadedPlaces
        moves = loadedMoves
        progress = loadedProgress
        queueTop = loadedQueueTop
        subscription = loadedSubscription
        cachedFeedURL = loadedFeedURL
        globalExpiry = loadedExpiry

        // The share preview's art can come later: nothing on the page moves for it.
        if showArt == nil, let url = show?.artworkURL, let (data, _) = try? await URLSession.shared.data(from: url) {
            showArt = UIImage(data: data)
        }
    }

    private func caption(_ place: Place?) -> String? {
        switch place {
        case .inbox: "In Inbox"
        case .queue: "Queued"
        case .archive(.played): "Played"
        case .archive(.dismissed): "Removed"
        case .archive, nil: nil
        }
    }

    private func episodeRow(_ episode: EpisodeInfo) -> some View {
        let place = places[episode.key]
        let played = place == Place.archive(.played)
        let art: ShowArt? = show.map { ShowArt(title: $0.title, artworkURL: $0.artworkURL, feedURL: $0.feedURL ?? feedURL) }
        return EpisodeRow(episode: episode, identifier: "episode",
                          statuses: caption(place).map { [$0] } ?? [], move: moves[episode.key],
                          download: model.downloadState(episode), played: played,
                          progress: progress[episode.key] ?? 0, art: art,
                          isOpen: openRow == episode.key,
                          toggle: { openRow = openRow == episode.key ? nil : episode.key },
                          actions: actions(episode, place: place))
            .swipeActions(edge: .leading) {
                if place != .queue {
                    Button("Add to Queue", systemImage: "text.badge.plus") {
                        Task { await model.change { try await model.library.addToQueue(episode.key) } }
                    }
                    .tint(.accentColor)
                }
            }
            .swipeActions(edge: .trailing) {
                if isShared {
                    Button("Delete", systemImage: "trash", role: .destructive) { delete(episode) }
                }
                if played {
                    Button("Mark Unplayed", systemImage: "circle") {
                        Task { await model.change { try await model.library.markUnplayed(episode.key) } }
                    }
                } else {
                    Button("Mark Played", systemImage: "checkmark.circle") {
                        Task { await model.change { try await model.library.markPlayed(episode.key) } }
                    }
                }
            }
    }

    /// Play Next, Add to Queue, Played or Unplayed, Share, Remove, and Delete for shared files, when they apply.
    private func actions(_ episode: EpisodeInfo, place: Place?) -> [RowAction] {
        let key = episode.key
        var actions: [RowAction] = []
        if !queueTop.contains(key) { actions.append(.playNext(key, model)) }
        if place != .queue { actions.append(.addToQueue(key, model)) }
        actions.append(place == Place.archive(.played) ? .unplayed(key, model) : .played(key, model))
        actions.append(.share)
        switch place {
        case .inbox: actions.append(.change("Remove", "minus.circle", destructive: true, model) { try await $0.dismiss(key) })
        case .queue: actions.append(.change("Remove", "minus.circle", destructive: true, model) { try await $0.removeFromQueue(key) })
        default: break
        }
        if isShared {
            actions.append(RowAction(title: "Delete", symbol: "trash", destructive: true) { delete(episode) })
        }
        return actions
    }

    /// Deletes a shared file and its episode, wherever it is.
    private func delete(_ episode: EpisodeInfo) {
        model.player.unload(episode.key)
        model.sharedStore?.delete(episode.audioURL)
        Task { await model.change { try await model.library.deleteSharedEpisode(episode.key) } }
    }

    /// One line saying what happens to new episodes; tapping it opens the sheet that changes it.
    /// A show you don't follow offers Subscribe instead; the built-in shared show offers neither.
    @ViewBuilder private var newEpisodesRow: some View {
        if subscription == nil, isShared {
            Section {
                Text("Files you share to Casterr live here, on this iPhone only, until you delete them.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        } else if let subscription {
            Section {
                Button { editingNewEpisodes = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: symbol(for: subscription.level))
                            .foregroundStyle(.tint)
                            .frame(width: 30, height: 30)
                            .background(Color.tangerine.opacity(0.12), in: .rect(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("New episodes").foregroundStyle(.primary)
                            Text(newEpisodesSummary(subscription)).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                    }
                    .contentShape(.rect)
                }
                // A plain row, not tinted like a button.
                .buttonStyle(.plain)
                .accessibilityIdentifier("newEpisodesRow")
            }
        }
    }

    private func symbol(for level: TriageLevel) -> String {
        switch level {
        case .inbox: "tray"
        case .autoQueue: "text.badge.plus"
        case .playNext: "text.line.first.and.arrowtriangle.forward"
        case .skip: "archivebox"
        }
    }

    private func newEpisodesSummary(_ subscription: SubscriptionInfo) -> String {
        switch subscription.level {
        case .inbox:
            let expiry = subscription.expiryOverride ?? globalExpiry
            let base = expiry == .never ? "Go to your Inbox and stay until you remove them"
                                        : "Go to your Inbox, removed after \(expiry.title)"
            return subscription.expiryOverride == nil ? base + " (your default)" : base
        case .autoQueue: return "Go to the end of your Queue"
        case .playNext: return "Play next, right after what's playing"
        case .skip: return "Skipped, only on this page"
        }
    }

    @ViewBuilder private var header: some View {
        if let show {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 16) {
                    ArtworkView(url: show.artworkURL, title: show.title, size: 120)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(show.title).font(.title3.weight(.black))
                        if let author = show.author {
                            Text(author).foregroundStyle(.secondary)
                        }
                    }
                }
                if let description = show.plainSummary {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(description)
                            .font(.subheadline)
                            .lineLimit(fullDescription ? nil : 2)
                        Button(fullDescription ? "Less" : "More") { withAnimation { fullDescription.toggle() } }
                            .font(.subheadline.weight(.semibold))
                            .buttonStyle(.borderless)
                    }
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        }
    }

    @ViewBuilder private var failingFeed: some View {
        if show?.lastRefreshError != nil {
            HStack(spacing: 12) {
                CassyView(job: .error, size: 54).accessibilityHidden(true)
                Text(refreshStatus)
            }
        }
    }

    private var refreshStatus: String {
        let line = "This feed is playing hide and seek. I'll look again on the next refresh."
        guard let last = show?.lastRefreshSuccess else { return line }
        return "\(line) Last heard from it \(last.formatted(.relative(presentation: .named)))."
    }
}

/// A wide capsule button under the show header: filled while it invites an action, soft once it's on.
private struct ShowPageButton: View {
    let title: String
    let symbol: String
    let on: Bool
    let action: () -> Void

    var body: some View {
        let label = Label(title, systemImage: symbol).labelStyle(.titleAndIcon).frame(maxWidth: .infinity)
        if on {
            Button(action: action) { label }.buttonStyle(.bordered)
                .controlSize(.large).buttonBorderShape(.capsule)
        } else {
            Button(action: action) { label }.filledButton()
                .controlSize(.large).buttonBorderShape(.capsule)
        }
    }
}
