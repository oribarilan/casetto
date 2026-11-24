import CasterrCore
import Foundation
import NowPlaying

/// Feeds the lock screen, Control Center and headphone controls from `Player`.
@MainActor
final class NowPlayingBridge: MediaSessionRepresentable {
    let id = "casterr.player"
    /// AirPods send a double press as next and a triple press as previous; other headphones and cars send the same.
    enum Press { case double, triple }

    private let player: Player
    private let onButton: @MainActor (Press) async -> Void

    init(player: Player, onButton: @escaping @MainActor (Press) async -> Void) {
        self.player = player
        self.onButton = onButton
    }

    var content: (any MediaContentRepresentable)? {
        guard let episode = player.episode else { return nil }
        return PodcastContent(
            id: episode.key.rawValue,
            episodeTitle: episode.title,
            showName: player.show?.title ?? "",
            releaseDate: episode.publishDate,
            type: .audio,
            duration: player.duration.map { .finite($0) },
            artwork: player.show?.artworkURL.map(Self.artwork)
        )
    }

    var playbackSnapshot: MediaPlaybackSnapshot? {
        guard player.episode != nil else { return nil }
        return MediaPlaybackSnapshot(
            state: player.isPlaying ? .playing(rate: Float(player.speed.value)) : .paused,
            elapsedTime: player.position,
            timestamp: .now
        )
    }

    var commands: [MediaCommand] {
        let player = player
        return [
            .play { try await player.resume() },
            .pause { try await player.pause() },
            .togglePlayPause { try await player.togglePlayPause() },
            .skipForward(preferredIntervals: [Player.skipForwardSeconds]) { _ in player.skipForward() },
            .skipBackward(preferredIntervals: [Player.skipBackSeconds]) { _ in player.skipBack() },
            .seekToPosition { player.seek(to: $0) },
            .next { [onButton] in await onButton(.double) },
            .previous { [onButton] in await onButton(.triple) },
        ]
    }

    private static func artwork(_ url: URL) -> Artwork {
        Artwork(id: url.absoluteString) { _ in
            let (data, _) = try await URLSession.shared.data(from: url)
            return try ArtworkRepresentation(data: data)
        }
    }
}
