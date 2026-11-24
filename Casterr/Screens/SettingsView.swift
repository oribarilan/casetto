import CasterrCore
import SwiftUI

/// The sections of Settings, so a link can open it at the right one.
enum SettingsSection: Hashable {
    case inbox, downloads, playback, buttons
}

/// Global defaults: how long episodes wait in the Inbox, how many Queue episodes stay downloaded,
/// the default speed, voice boost, and what headphone and car buttons do; and Clear Cache. Per-show settings live on the show page and in Now Playing.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    var focus: SettingsSection?

    @State private var expiry: InboxExpiry = .standard
    @State private var downloads = 3
    /// The top Queue episodes for the largest choice, so each choice sizes its share at once.
    @State private var queueTop: [EpisodeInfo] = []
    @State private var speed = 1.0
    @State private var voiceBoost = false
    @State private var doublePress = ButtonAction.doublePressDefault
    @State private var triplePress = ButtonAction.triplePressDefault
    @State private var highlighted: SettingsSection?
    /// Bytes of kept show art, other downloaded responses, and saved popular lists.
    @State private var cacheSize = 0
    @State private var downloadsSize = 0
    /// Shows "Cleared" on the button for a moment after Clear Cache.
    @State private var cleared = false

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
                        if let size = DownloadSize.caption(queueTop, count: downloads) {
                            Text(size)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("downloadEstimate")
                        }
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
                    Toggle("Voice boost", isOn: Binding(get: { voiceBoost }, set: { isOn in
                        voiceBoost = isOn
                        Task {
                            await model.change {
                                try await model.library.setGlobalVoiceBoost(isOn)
                                try await player.reloadVoiceBoost()
                            }
                        }
                    }))
                    .accessibilityIdentifier("voiceBoostDefault")
                    .listRowBackground(rowBackground(.playback))
                } header: {
                    Text("Playback")
                } footer: {
                    Text("Voice boost evens out loud and quiet voices. A show can have its own speed and voice boost from Now Playing.")
                }
                .id(SettingsSection.playback)

                Section {
                    buttonPicker("Double press", selection: $doublePress, double: true)
                    buttonPicker("Triple press", selection: $triplePress, double: false)
                } header: {
                    Text("Headphone and car buttons")
                } footer: {
                    Text(ButtonAction.footer(double: doublePress, triple: triplePress))
                        .accessibilityIdentifier("buttonsFooter")
                }
                .id(SettingsSection.buttons)

                Section {
                    LabeledContent("Downloaded episodes", value: downloadsSize.formatted(.byteCount(style: .file)))
                        .accessibilityIdentifier("downloadsSize")
                    LabeledContent("Saved art and popular lists", value: cacheSize.formatted(.byteCount(style: .file)))
                        .accessibilityIdentifier("cacheSize")
                    Button(action: clearCache) {
                        if cleared {
                            Label("Cleared", systemImage: "checkmark")
                        } else {
                            Text("Clear Cache")
                        }
                    }
                    .disabled(cleared)
                } header: {
                    Text("Storage")
                } footer: {
                    Text("Keep downloaded decides which episodes stay downloaded. Clear Cache deletes saved show art and popular lists, which download again when needed.")
                }

                Section {
                    Button {
                        model.whatsNew = AppModel.changelog.releases
                    } label: {
                        LabeledContent {
                            Text("What's New").foregroundStyle(.secondary)
                        } label: {
                            Text("Version \(AppModel.version)").foregroundStyle(Color(.label))
                        }
                    }
                    .accessibilityIdentifier("version")
                } header: {
                    Text("About")
                } footer: {
                    Text("Build \(AppModel.build)")
                }
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

    private func buttonPicker(_ title: String, selection: Binding<ButtonAction>, double: Bool) -> some View {
        Picker(title, selection: Binding(get: { selection.wrappedValue }, set: { action in
            selection.wrappedValue = action
            Task { await model.change { try await model.library.setButtonAction(action, forDoublePress: double) } }
        })) {
            ForEach(ButtonAction.allCases, id: \.self) { Text($0.title).tag($0) }
        }
        .listRowBackground(rowBackground(.buttons))
    }

    private func rowBackground(_ section: SettingsSection) -> Color {
        highlighted == section ? Color.tangerine.opacity(0.14) : Color(.secondarySystemGroupedBackground)
    }

    private func load() async {
        expiry = (try? await model.library.globalExpiry()) ?? .standard
        downloads = (try? await model.library.downloadCount()) ?? 3
        queueTop = (try? await model.library.queueEpisodes(limit: DownloadCount.choices.max() ?? 10)) ?? []
        speed = ((try? await model.library.globalSpeed())?.value ?? 1.0)
        voiceBoost = (try? await model.library.globalVoiceBoost()) ?? false
        if let actions = try? await model.library.buttonActions() {
            doublePress = actions.double
            triplePress = actions.triple
        }
        cacheSize = currentCacheSize
        downloadsSize = model.downloader.store.size
    }

    private var currentCacheSize: Int { URLCache.shared.currentDiskUsage + model.savedCharts.size + ArtCache.diskSize }

    private func clearCache() {
        ArtCache.clear()
        model.savedCharts.clear()
        withAnimation { cleared = true }
        Task {
            // iOS empties its download cache in the background, so read the size again as it does.
            for step in 1...6 {
                try? await Task.sleep(for: .milliseconds(500))
                cacheSize = currentCacheSize
                if step == 4 { withAnimation { cleared = false } }
            }
        }
    }
}
