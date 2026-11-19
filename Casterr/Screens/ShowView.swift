import CasterrCore
import SwiftUI

/// One show: its episodes newest first, refresh status, triage settings, speed override, and unsubscribe.
struct ShowView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let showKey: ShowKey

    @State private var show: ShowInfo?
    @State private var episodes: [EpisodeInfo] = []
    @State private var places: [EpisodeKey: Place] = [:]
    @State private var moves: [EpisodeKey: LastMove] = [:]
    @State private var subscription: SubscriptionInfo?
    @State private var globalExpiry: InboxExpiry = .days(7)
    @State private var confirmingUnsubscribe = false

    var body: some View {
        List {
            Section {
                if let error = show?.lastRefreshError {
                    Label(refreshStatus(error: error), systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                if let speedOverride = subscription?.speedOverride {
                    LabeledContent("Speed (this show)") {
                        HStack {
                            Text("\(speedOverride.value, format: .number.precision(.fractionLength(1)))×")
                            Button("Reset") {
                                Task { await model.change { try await model.library.setSpeedOverride(showKey, to: nil) } }
                            }
                        }
                    }
                }
            }
            if let subscription {
                Section("New Episodes") {
                    Picker("Send to", selection: Binding(get: { subscription.level }, set: { level in
                        Task { await model.change { try await model.library.setLevel(showKey, to: level) } }
                    })) {
                        ForEach(TriageLevel.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .accessibilityIdentifier("levelPicker")
                    if subscription.level == .inbox {
                        Picker("Remove after", selection: Binding(get: { subscription.expiryOverride }, set: { expiry in
                            Task { await model.change { try await model.library.setExpiryOverride(showKey, to: expiry) } }
                        })) {
                            Text("Default (\(globalExpiry.title))").tag(InboxExpiry?.none)
                            ForEach(InboxExpiry.choices, id: \.self) { Text($0.title).tag(Optional($0)) }
                        }
                        .accessibilityIdentifier("expiryPicker")
                    }
                }
            }
            Section("Episodes") {
                ForEach(episodes, id: \.key) { episode in
                    EpisodeRow(episode: episode, identifier: "episode",
                               caption: caption(places[episode.key]), move: moves[episode.key])
                    .swipeActions(edge: .leading) {
                        if places[episode.key] != .queue {
                            Button("Add to Queue", systemImage: "text.badge.plus") {
                                Task { await model.change { try await model.library.addToQueue(episode.key) } }
                            }
                            .tint(.accentColor)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if places[episode.key] == .archive(.played) {
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
            }
        }
        .navigationTitle(show?.title ?? "")
        .toolbar {
            Menu("More", systemImage: "ellipsis") {
                Button("Unsubscribe", systemImage: "minus.circle", role: .destructive) { confirmingUnsubscribe = true }
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
        globalExpiry = (try? await library.globalExpiry()) ?? .days(7)
    }

    private func caption(_ place: Place?) -> String? {
        switch place {
        case .inbox: "In Inbox"
        case .queue: "Queued"
        case .archive(.played): "Played"
        case .archive(.dismissed): "Dismissed"
        case .archive, nil: nil
        }
    }

    private func refreshStatus(error: String) -> String {
        guard let last = show?.lastRefreshSuccess else { return error }
        return "\(error). Last updated \(last.formatted(.relative(presentation: .named)))."
    }
}
