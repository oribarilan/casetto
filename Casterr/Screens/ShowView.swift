import CasterrCore
import SwiftUI

/// One show: its episodes newest first, refresh status, speed override, and unsubscribe.
struct ShowView: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    @Environment(\.dismiss) private var dismiss
    let showKey: ShowKey

    @State private var show: ShowInfo?
    @State private var episodes: [EpisodeInfo] = []
    @State private var places: [EpisodeKey: Place] = [:]
    @State private var speedOverride: PlaybackSpeed?
    @State private var confirmingUnsubscribe = false

    var body: some View {
        List {
            Section {
                if let error = show?.lastRefreshError {
                    Label(refreshStatus(error: error), systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                if let speedOverride {
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
            Section("Episodes") {
                ForEach(episodes, id: \.key) { episode in
                    Button {
                        Task { await model.change { try await player.play(episode.key) } }
                    } label: {
                        EpisodeRow(episode: episode, caption: caption(places[episode.key]))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("episode")
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
        speedOverride = try? await library.subscriptions().first { $0.showKey == showKey }?.speedOverride
    }

    private func caption(_ place: Place?) -> String? {
        switch place {
        case .queue: "Queued"
        case .archive(.played): "Played"
        case nil: nil
        }
    }

    private func refreshStatus(error: String) -> String {
        guard let last = show?.lastRefreshSuccess else { return error }
        return "\(error). Last updated \(last.formatted(.relative(presentation: .named)))."
    }
}
