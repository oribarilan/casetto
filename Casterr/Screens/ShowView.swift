import CasterrCore
import SwiftUI

/// One show: a header with its description, what happens to new episodes, the episodes left to hear,
/// played episodes folded away, refresh status, speed override, and unsubscribe.
struct ShowView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let showKey: ShowKey

    @State private var show: ShowInfo?
    @State private var episodes: [EpisodeInfo] = []
    @State private var places: [EpisodeKey: Place] = [:]
    @State private var moves: [EpisodeKey: LastMove] = [:]
    @State private var subscription: SubscriptionInfo?
    @State private var globalExpiry: InboxExpiry = .standard
    @State private var confirmingUnsubscribe = false
    @State private var editingNewEpisodes = false
    @State private var showingPlayed = false
    @State private var fullDescription = false
    /// Where an unfollowed show's feed came from, for Subscribe.
    @State private var cachedFeedURL: URL?
    @State private var subscribing = false
    /// The show's art, for the share sheet's preview.
    @State private var showArt: UIImage?

    /// The built-in show for files shared to Casterr: Delete instead of following.
    private var isShared: Bool { showKey == .shared }

    var body: some View {
        List {
            header
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
            if subscription != nil {
                Menu("More", systemImage: "ellipsis") {
                    Button("Unsubscribe", systemImage: "minus.circle", role: .destructive) { confirmingUnsubscribe = true }
                }
            }
        }
        .confirmationDialog("Unsubscribe from this show?", isPresented: $confirmingUnsubscribe) {
            Button("Unsubscribe", role: .destructive) {
                Task {
                    await model.change { try await model.feeds.unsubscribe(showKey) }
                    dismiss()
                }
            }
        } message: {
            Text("Episodes you queued stay in your Queue.")
        }
        .refreshable { await model.refresh() }
        .task(id: model.revision) { await load() }
    }

    private func load() async {
        let library = model.library
        show = try? await library.show(showKey)
        episodes = (try? await library.episodes(of: showKey)) ?? []
        var loaded: [EpisodeKey: Place] = [:]
        for episode in episodes {
            if let place = try? await library.place(of: episode.key) { loaded[episode.key] = place }
        }
        places = loaded
        moves = await model.moves(of: episodes.map(\.key))
        subscription = try? await library.subscriptions().first { $0.showKey == showKey }
        cachedFeedURL = try? await library.cachedFeedURL(of: showKey)
        globalExpiry = (try? await library.globalExpiry()) ?? .standard
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
        let art: ShowArt? = show.map { ShowArt(title: $0.title, artworkURL: $0.artworkURL) }
        return EpisodeRow(episode: episode, identifier: "episode",
                          caption: caption(place), move: moves[episode.key],
                          art: art)
            .contextMenu {
                if isShared {
                    Button("Delete", systemImage: "trash", role: .destructive) { delete(episode) }
                } else {
                    ArtShareLink(share: ShareText.episode(episode, show: show, at: nil), art: showArt) {
                        Label("Share Episode", systemImage: "square.and.arrow.up")
                    }
                }
            }
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
        } else if subscription == nil, let feedURL = cachedFeedURL {
            Section {
                Button {
                    subscribing = true
                    Task {
                        await model.change { _ = try await model.feeds.subscribe(to: feedURL) }
                        subscribing = false
                    }
                } label: {
                    Label(subscribing ? "Subscribing…" : "Subscribe", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(subscribing)
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("subscribeShow")
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
