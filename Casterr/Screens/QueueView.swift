import CasterrCore
import SwiftUI

/// Home screen: the Queue in play order. The first item says whether it's playing, paused, or up next.
/// Tap a row for its actions, long-press to drag it into place, swipe left to remove it.
struct QueueView: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    @State private var items: [EpisodeInfo] = []
    @State private var moves: [EpisodeKey: LastMove] = [:]
    @State private var inboxCount = 0
    @State private var inboxEpisodes = 0
    @State private var art: [ShowKey: ShowArt] = [:]
    @State private var progress: [EpisodeKey: TimeInterval] = [:]
    @State private var starredShows: Set<ShowKey> = []
    /// The row whose action line is open.
    @State private var openRow: EpisodeKey?
    @State private var loaded = false

    var body: some View {
        List {
            if inboxCount > 0 {
                NavigationLink(value: Route.inbox) {
                    Label("Inbox · \(inboxCount) new", systemImage: "tray")
                }
            }
            ForEach(Array(items.enumerated()), id: \.element.key) { index, episode in
                let state = index == 0 ? firstState(episode) : nil
                EpisodeRow(
                    episode: episode, identifier: "queueItem",
                    label: state?.caption, move: moves[episode.key], starred: starredShows.contains(episode.showKey),
                    download: model.downloadState(episode), progress: progress[episode.key] ?? 0,
                    art: art[episode.showKey],
                    captionSymbol: state?.symbol, animateSymbol: state?.caption == "Playing",
                    isOpen: openRow == episode.key,
                    toggle: { openRow = openRow == episode.key ? nil : episode.key },
                    actions: actions(episode, upNext: index < 2)
                )
                .swipeActions(edge: .trailing) {
                    // "Remove", not "Delete": the episode leaves the Queue and stays on its show page.
                    Button("Remove", systemImage: "minus.circle", role: .destructive) { remove(episode) }
                }
            }
            .onMove { from, to in
                guard let source = from.first else { return }
                let key = items[source].key
                let destination = to > source ? to - 1 : to
                items.move(fromOffsets: from, toOffset: to)
                Task { await model.change(.episodes) { try await model.library.movePlayable(key, to: destination) } }
            }
        }
        .overlay {
            if loaded && items.isEmpty {
                if inboxCount > 0 {
                    // Something is waiting, so point at it instead of suggesting new shows.
                    CassyEmptyState(
                        job: .idle, title: inboxTitle,
                        message: "Have a look and queue what you want to hear."
                    ) {
                        Button("Open Inbox") { model.queuePath = [.inbox] }
                            .filledButton()
                            .buttonBorderShape(.capsule)
                    }
                } else {
                    CassyEmptyState(
                        job: .asleep, title: "Silence. Lovely, but let's fix that.",
                        message: "Star the shows you never miss and I'll queue their new episodes right here."
                    ) {
                        Button("Find Shows") { model.tab = .shows }
                            .filledButton()
                            .buttonBorderShape(.capsule)
                    }
                }
            }
        }
        // While shows refresh, a thin line under the bar fills as each one is checked. Nothing in the list moves.
        .overlay(alignment: .top) { RefreshLine(progress: model.refreshProgress) }
        // The same grey background whether the Queue is empty or full.
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Queue")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: Route.settings(nil)) {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        // Hand off to Cassy right away instead of holding the system spinner.
        .refreshable { Task { await model.refresh() } }
        .reload(on: "\(model.revision([.episodes, .feeds, .follows]))|\(player.episode?.key.rawValue ?? "")") {
            await load()
        }
    }

    /// Play Next (not on the first two rows, where it would change nothing), Played, Download
    /// when it applies, Share, Show, Remove.
    private func actions(_ episode: EpisodeInfo, upNext: Bool) -> [RowAction] {
        (upNext ? [] : [.playNext(episode.key, model)]) + [.played(episode.key, model)]
            + RowAction.downloadOnCellular(episode, model) + [
                .share, .show(episode.showKey, model),
                RowAction(title: "Remove", symbol: "minus.circle", destructive: true) { remove(episode) },
            ]
    }

    private func remove(_ episode: EpisodeInfo) {
        items.removeAll { $0.key == episode.key }
        Task { await model.change(.episodes) { try await model.library.removeFromQueue(episode.key) } }
    }

    /// The first episode's label: playing, paused, or up next.
    private func firstState(_ episode: EpisodeInfo) -> (caption: String, symbol: String?) {
        guard player.episode?.key == episode.key else { return ("Up next", nil) }
        return player.isPlaying ? ("Playing", "waveform") : ("Paused", nil)
    }

    private var inboxTitle: String {
        switch inboxEpisodes {
        case 0: "Your Queue is empty, and I have a suggestion for you."
        case 1: "Your Queue is empty, but 1 new episode is waiting."
        default: "Your Queue is empty, but \(inboxEpisodes) new episodes are waiting."
        }
    }

    private func load() async {
        let keys = (try? await model.library.playableQueue()) ?? []
        items = await model.episodes(keys)
        art = (try? await model.library.showArt()) ?? [:]
        moves = await model.moves(of: keys)
        progress = await model.progress(of: keys)
        starredShows = Set(((try? await model.library.subscriptions()) ?? []).filter(\.starred).map(\.showKey))
        inboxEpisodes = (try? await model.library.inboxCount()) ?? 0
        inboxCount = inboxEpisodes + ((try? await model.library.ruleCards().count) ?? 0)
        loaded = true
    }
}

/// A thin tangerine line that fills from 0 to 1, then fades out when `progress` goes back to nil.
private struct RefreshLine: View {
    let progress: Double?
    @State private var shown: Double = 0

    var body: some View {
        Rectangle()
            .fill(Color.tangerine)
            .frame(height: 2)
            .scaleEffect(x: shown, anchor: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(progress == nil ? 0 : 1)
            .animation(.easeOut(duration: 0.4), value: progress == nil)
            .onChange(of: progress) { old, new in
                if old == nil, let new {
                    shown = new  // A new refresh starts where it is, while the line is still hidden.
                } else {
                    // Fill to each report, and to the end as the line fades out.
                    withAnimation(.easeOut(duration: 0.3)) { shown = new ?? 1 }
                }
            }
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel("Checking for new episodes")
            .accessibilityValue(progress.map { "\(Int($0 * 100)) percent" } ?? "")
            .accessibilityHidden(progress == nil)
    }
}
