import CasterrCore
import SwiftUI

/// New episodes waiting for a decision, newest first.
struct InboxView: View {
    @Environment(AppModel.self) private var model
    @State private var items: [EpisodeInfo] = []
    @State private var moves: [EpisodeKey: LastMove] = [:]
    @State private var expiry: InboxExpiry = .days(7)
    @State private var loaded = false

    var body: some View {
        List(items, id: \.key) { episode in
            EpisodeRow(episode: episode, identifier: "inboxItem", move: moves[episode.key])
                .swipeActions(edge: .leading) {
                    Button("Add to Queue", systemImage: "text.badge.plus") {
                        Task { await model.change { try await model.library.addToQueue(episode.key) } }
                    }
                    .tint(.accentColor)
                }
                .swipeActions(edge: .trailing) {
                    Button("Dismiss", systemImage: "xmark", role: .destructive) {
                        Task { await model.change { try await model.library.dismiss(episode.key) } }
                    }
                }
        }
        .overlay {
            if loaded && items.isEmpty {
                ContentUnavailableView("Inbox is empty", systemImage: "tray",
                                       description: Text("New episodes from Inbox shows land here."))
            }
        }
        .navigationTitle("Inbox")
        .toolbar {
            Menu("Expiry", systemImage: "clock") {
                Picker("Remove after", selection: Binding(get: { expiry }, set: { new in
                    Task { await model.change { try await model.library.setGlobalExpiry(new) } }
                })) {
                    ForEach(InboxExpiry.choices, id: \.self) { Text($0.title).tag($0) }
                }
            }
        }
        .refreshable { await model.refresh() }
        .task(id: model.revision) { await load() }
    }

    private func load() async {
        let keys = (try? await model.library.inbox()) ?? []
        items = await model.episodes(keys)
        moves = await model.moves(of: keys)
        expiry = (try? await model.library.globalExpiry()) ?? .days(7)
        loaded = true
    }
}

extension InboxExpiry {
    var title: String {
        switch self {
        case .days(let days): "\(days) days"
        case .never: "Never"
        }
    }
}

extension TriageLevel {
    var title: String {
        switch self {
        case .inbox: "Inbox"
        case .autoQueue: "Add to Queue"
        case .playNext: "Play Next"
        case .skip: "Skip"
        }
    }
}
