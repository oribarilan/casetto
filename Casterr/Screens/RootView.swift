import CasterrCore
import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showingNowPlaying = false
    /// A show tapped in Now Playing, opened once the sheet has closed.
    @State private var showToOpen: ShowKey?
    @State private var showingOnboarding = false

    var body: some View {
        @Bindable var model = model
        // A tap on Queue always opens the Queue itself; Shows and Bookmarks keep the page the listener left.
        // iOS goes back to a tab's main page on a second tap. Only taps pass through this setter, so pages
        // the app opens by itself, such as the Inbox from the refresh message, stay open.
        TabView(selection: Binding(get: { model.tab }, set: { tab in
            if tab == .queue { model.queuePath = [] }
            model.tab = tab
        })) {
            Tab("Queue", systemImage: "list.bullet", value: AppTab.queue) {
                NavigationStack(path: $model.queuePath) { QueueView().routes() }
            }
            Tab("Shows", systemImage: "square.stack", value: AppTab.shows) {
                NavigationStack(path: $model.showsPath) { ShowsView().routes() }
            }
            Tab("Bookmarks", systemImage: "bookmark", value: AppTab.bookmarks) {
                NavigationStack(path: $model.bookmarksPath) { BookmarksView().routes() }
            }
        }
        .bookmarkToast()
        .cassyToast()
        // The bookmark toast opens its bookmark in the Bookmarks tab, from Now Playing too.
        .onChange(of: model.openingBookmark) { _, request in
            guard request != nil else { return }
            showingNowPlaying = false
            model.bookmarksPath = []
            model.tab = .bookmarks
        }
        .tabViewBottomAccessory(isEnabled: player.episode != nil || model.upNext != nil) {
            if player.episode != nil {
                MiniPlayer { showingNowPlaying = true }
            } else if let upNext = model.upNext {
                UpNextBar(upNext: upNext)
            }
        }
        .sheet(isPresented: $showingNowPlaying, onDismiss: openTappedShow) {
            NowPlayingView { show in
                showToOpen = show
                showingNowPlaying = false
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(get: { model.whatsNew != nil }, set: { if !$0 { model.whatsNew = nil } })) {
            WhatsNewView(releases: model.whatsNew ?? [])
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView { hasSeenOnboarding = true; showingOnboarding = false }
        }
        .task {
            if !hasSeenOnboarding, (try? await model.library.subscriptions().isEmpty) == true {
                showingOnboarding = true
            }
            // After the launch settles, so the toast isn't lost under the first screen.
            try? await Task.sleep(for: .seconds(1))
            model.greetUpdate(hasSeenOnboarding: hasSeenOnboarding)
        }
    }

    private func openTappedShow() {
        guard let show = showToOpen else { return }
        showToOpen = nil
        model.tab = .shows
        model.showsPath = [.show(show)]
    }
}

enum AppTab: Hashable {
    case queue
    case shows
    case bookmarks
}

extension View {
    func routes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .inbox: InboxView()
            case .show(let key): ShowView(showKey: key)
            case .directoryShow(let show): if let key = ShowKey(feedURL: show.feedURL) { ShowView(showKey: key, feedURL: show.feedURL, preview: show) }
            case .settings(let focus): SettingsView(focus: focus)
            }
        }
    }
}

private struct MiniPlayer: View {
    @Environment(Player.self) private var player
    let open: () -> Void

    var body: some View {
        HStack {
            ArtworkView(url: player.show?.artworkURL, title: player.show?.title ?? "", size: 34)
            Button(action: open) {
                VStack(alignment: .leading) {
                    Text(player.episode?.title ?? "").lineLimit(1)
                    Text(player.show?.title ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("miniPlayer")
            Button {
                Task { try? await player.togglePlayPause() }
            } label: {
                if player.isPlaying {
                    PauseMeter()
                } else {
                    Image(systemName: "play.fill").font(.title2)
                }
            }
            .frame(width: 30, height: 30)
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
        }
        .padding(.horizontal)
    }
}

/// The bar while nothing is loaded: the new episode the Queue would start, and a play button. A started episode is
/// loaded instead, so the mini player shows it.
private struct UpNextBar: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    let upNext: UpNext

    var body: some View {
        HStack {
            ArtworkView(url: upNext.artworkURL, title: upNext.showTitle, size: 34)
            Button {
                model.tab = .queue
                model.queuePath = []
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text(upNext.caption).font(.caption.weight(.bold)).foregroundStyle(.tint)
                    Text(upNext.episode.title).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("upNextBar")
            Button("Play", systemImage: "play.fill") {
                Task { try? await player.resume() }
            }
            .labelStyle(.iconOnly)
            .font(.title2)
            .accessibilityIdentifier("upNextPlay")
        }
        .padding(.horizontal)
    }
}

enum Route: Hashable {
    case inbox
    case show(ShowKey)
    /// A show from Find Shows, with what the directory knows: its page fetches the feed without following it.
    case directoryShow(DirectoryShow)
    case settings(SettingsSection?)
}

extension TimeInterval {
    /// 1:02:03 or 2:03.
    var clock: String {
        let total = Int(max(self, 0))
        let (h, m, s) = (total / 3600, total % 3600 / 60, total % 60)
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
