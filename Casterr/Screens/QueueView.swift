import CasterrCore
import SwiftUI

/// Home screen: the Queue in play order. The first item is Now Playing.
struct QueueView: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    @State private var items: [EpisodeInfo] = []
    @State private var moves: [EpisodeKey: LastMove] = [:]
    @State private var inboxCount = 0
    @State private var loaded = false

    var body: some View {
        List {
            if inboxCount > 0 {
                NavigationLink(value: Route.inbox) {
                    Label("New (\(inboxCount))", systemImage: "tray")
                }
            }
            ForEach(Array(items.enumerated()), id: \.element.key) { index, episode in
                EpisodeRow(episode: episode, identifier: "queueItem",
                           caption: index == 0 ? "Now Playing" : nil, move: moves[episode.key])
            }
            .onMove { from, to in
                guard let source = from.first else { return }
                let key = items[source].key
                let destination = to > source ? to - 1 : to
                items.move(fromOffsets: from, toOffset: to)
                Task { await model.change { try await model.library.move(key, to: destination) } }
            }
            .onDelete { offsets in
                let keys = offsets.map { items[$0].key }
                items.remove(atOffsets: offsets)
                Task { await model.change { for key in keys { try await model.library.removeFromQueue(key) } } }
            }
        }
        .overlay {
            if loaded && items.isEmpty {
                ContentUnavailableView {
                    Label("Nothing queued", systemImage: "list.bullet")
                } description: {
                    Text("Add episodes from your shows.")
                } actions: {
                    NavigationLink("Your Shows", value: Route.shows)
                }
            }
        }
        .navigationTitle("Queue")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: Route.shows) { Label("Shows", systemImage: "square.stack") }
            }
        }
        .refreshable { await model.refresh() }
        .task(id: "\(model.revision)|\(player.episode?.key.rawValue ?? "")") { await load() }
    }

    private func load() async {
        let keys = (try? await model.library.queue()) ?? []
        items = await model.episodes(keys)
        moves = await model.moves(of: keys)
        inboxCount = (try? await model.library.inboxCount()) ?? 0
        loaded = true
    }
}
