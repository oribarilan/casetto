import CasterrCore
import SwiftUI

/// Home screen: the Queue in play order. The first item says whether it's playing, paused, or up next.
/// Long-press to drag an episode into place; swipe left to remove it.
struct QueueView: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    @State private var items: [EpisodeInfo] = []
    @State private var moves: [EpisodeKey: LastMove] = [:]
    @State private var inboxCount = 0
    @State private var inboxEpisodes = 0
    @State private var art: [ShowKey: ShowArt] = [:]
    @State private var loaded = false

    var body: some View {
        List {
            if model.refreshing {
                CassyView(job: .loading, size: 64)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }
            if inboxCount > 0 {
                NavigationLink(value: Route.inbox) {
                    Label("Inbox · \(inboxCount) new", systemImage: "tray")
                }
            }
            ForEach(Array(items.enumerated()), id: \.element.key) { index, episode in
                let state = index == 0 ? firstState(episode) : nil
                EpisodeRow(episode: episode, identifier: "queueItem",
                           caption: state?.caption, move: moves[episode.key],
                           downloaded: model.isDownloaded(episode), art: art[episode.showKey],
                           captionSymbol: state?.symbol, animateSymbol: state?.caption == "Playing")
                .swipeActions(edge: .trailing) {
                    // "Remove", not "Delete": the episode leaves the Queue and stays on its show page.
                    Button("Remove", systemImage: "minus.circle", role: .destructive) {
                        items.removeAll { $0.key == episode.key }
                        Task { await model.change { try await model.library.removeFromQueue(episode.key) } }
                    }
                }
            }
            .onMove { from, to in
                guard let source = from.first else { return }
                let key = items[source].key
                let destination = to > source ? to - 1 : to
                items.move(fromOffsets: from, toOffset: to)
                Task { await model.change { try await model.library.movePlayable(key, to: destination) } }
            }
        }
        .overlay {
            if loaded && items.isEmpty {
                if inboxCount > 0 {
                    // Something is waiting, so point at it instead of suggesting new shows.
                    CassyEmptyState(job: .idle, title: inboxTitle,
                                    message: "Have a look and queue what you want to hear.") {
                        Button("Open Inbox") { model.queuePath = [.inbox] }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                    }
                } else {
                    CassyEmptyState(job: .asleep, title: "Silence. Lovely, but let's fix that.",
                                    message: "Star the shows you never miss and I'll queue their new episodes right here.") {
                        Button("Find Shows") { model.tab = .shows }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                    }
                }
            }
        }
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
        .task(id: "\(model.revision)|\(player.episode?.key.rawValue ?? "")") { await load() }
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
        inboxEpisodes = (try? await model.library.inboxCount()) ?? 0
        inboxCount = inboxEpisodes + ((try? await model.library.ruleCards().count) ?? 0)
        loaded = true
    }
}
