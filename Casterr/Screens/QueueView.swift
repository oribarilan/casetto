import CasterrCore
import SwiftUI

/// Home screen: the Queue in play order. The first item is Now Playing.
struct QueueView: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    @State private var items: [EpisodeInfo] = []
    @State private var loaded = false

    var body: some View {
        List {
            ForEach(Array(items.enumerated()), id: \.element.key) { index, episode in
                Button {
                    Task { await model.change { try await player.play(episode.key) } }
                } label: {
                    EpisodeRow(episode: episode, caption: index == 0 ? "Now Playing" : nil)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("queueItem")
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
        let library = model.library
        let keys = (try? await library.queue()) ?? []
        var episodes: [EpisodeInfo] = []
        for key in keys {
            if let episode = try? await library.episode(key) { episodes.append(episode) }
        }
        items = episodes
        loaded = true
    }
}

struct EpisodeRow: View {
    let episode: EpisodeInfo
    var caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let caption {
                Text(caption).font(.caption.bold()).foregroundStyle(.tint)
            }
            Text(episode.title).lineLimit(2)
            HStack {
                if let date = episode.publishDate { Text(date, format: .dateTime.day().month().year()) }
                if let duration = episode.duration { Text(duration.clock) }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
