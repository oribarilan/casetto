import CasterrCore
import SwiftUI

/// The sections of Settings, so a link can open it at the right one.
enum SettingsSection: Hashable {
    case inbox, downloads, playback
}

/// Global defaults only: how long episodes wait in the Inbox, how many Queue episodes stay downloaded,
/// and the default speed. Per-show settings live on the show page and in Now Playing.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    var focus: SettingsSection?

    @State private var expiry: InboxExpiry = .standard
    @State private var downloads = 3
    @State private var speed = 1.0
    @State private var highlighted: SettingsSection?

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Remove unplayed episodes after")
                        Picker("Remove unplayed episodes after", selection: Binding(get: { expiry }, set: { value in
                            Task { await model.change { try await model.library.setGlobalExpiry(value) } }
                        })) {
                            ForEach(InboxExpiry.choices, id: \.self) { Text($0.shortTitle).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .listRowBackground(rowBackground(.inbox))
                } header: {
                    Text("Inbox")
                } footer: {
                    Text("Your default for every show. A show can have its own in its New episodes settings.")
                }
                .id(SettingsSection.inbox)

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Keep downloaded")
                        Picker("Keep downloaded", selection: Binding(get: { downloads }, set: { value in
                            Task { await model.change { try await model.library.setDownloadCount(value) } }
                        })) {
                            ForEach(DownloadCount.choices, id: \.self) { Text($0 == 0 ? "Off" : "\($0)").tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .listRowBackground(rowBackground(.downloads))
                } header: {
                    Text("Downloads")
                } footer: {
                    Text("The top episodes of your Queue download on Wi-Fi.")
                }
                .id(SettingsSection.downloads)

                Section {
                    Picker("Default speed", selection: Binding(get: { speed }, set: { value in
                        Task {
                            await model.change {
                                try await model.library.setGlobalSpeed(PlaybackSpeed(value))
                                try await player.reloadSpeed()
                            }
                        }
                    })) {
                        ForEach(Array(stride(from: 1.0, through: 2.0, by: 0.1)), id: \.self) { value in
                            Text("\(value, format: .number.precision(.fractionLength(1)))×").tag((value * 10).rounded() / 10)
                        }
                    }
                    .listRowBackground(rowBackground(.playback))
                } header: {
                    Text("Playback")
                } footer: {
                    Text("A show can have its own speed from Now Playing.")
                }
                .id(SettingsSection.playback)
            }
            .navigationTitle("Settings")
            .task(id: model.revision) { await load() }
            .task {
                // Opened from a link: scroll to its section and highlight it for a moment.
                guard let focus else { return }
                proxy.scrollTo(focus, anchor: .top)
                highlighted = focus
                try? await Task.sleep(for: .seconds(1.6))
                withAnimation(.easeOut(duration: 0.6)) { highlighted = nil }
            }
        }
    }

    private func rowBackground(_ section: SettingsSection) -> Color {
        highlighted == section ? Color.tangerine.opacity(0.14) : Color(.secondarySystemGroupedBackground)
    }

    private func load() async {
        expiry = (try? await model.library.globalExpiry()) ?? .standard
        downloads = (try? await model.library.downloadCount()) ?? 3
        speed = ((try? await model.library.globalSpeed())?.value ?? 1.0)
    }
}
