import CasterrCore
import SwiftUI

struct RootView: View {
    @Environment(Player.self) private var player
    @State private var showingNowPlaying = false

    var body: some View {
        NavigationStack {
            QueueView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .shows: ShowsView()
                    case .show(let key): ShowView(showKey: key)
                    }
                }
        }
        .safeAreaInset(edge: .bottom) {
            if player.episode != nil {
                MiniPlayer { showingNowPlaying = true }
            }
        }
        .sheet(isPresented: $showingNowPlaying) { NowPlayingView() }
    }
}

private struct MiniPlayer: View {
    @Environment(Player.self) private var player
    let open: () -> Void

    var body: some View {
        HStack {
            Button(action: open) {
                VStack(alignment: .leading) {
                    Text(player.episode?.title ?? "").lineLimit(1)
                    Text(player.show?.title ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("miniPlayer")
            Button(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.fill" : "play.fill") {
                Task { try? await player.togglePlayPause() }
            }
            .labelStyle(.iconOnly)
            .font(.title2)
        }
        .padding()
        .background(.bar)
    }
}

enum Route: Hashable {
    case shows
    case show(ShowKey)
}

extension TimeInterval {
    /// 1:02:03 or 2:03.
    var clock: String {
        let total = Int(max(self, 0))
        let (h, m, s) = (total / 3600, total % 3600 / 60, total % 60)
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
