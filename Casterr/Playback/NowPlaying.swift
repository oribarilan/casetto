import CasterrCore
import Foundation
import NowPlaying

/// Feeds the lock screen, Control Center and headphone controls from `Player`.
@MainActor
final class NowPlayingBridge: MediaSessionRepresentable {
    let id = "casterr.player"
    private let player: Player

    init(player: Player) {
        self.player = player
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
        ]
    }

    private static func artwork(_ url: URL) -> Artwork {
        Artwork(id: url.absoluteString) { _ in
            let (data, _) = try await URLSession.shared.data(from: url)
            return try ArtworkRepresentation(data: data)
        }
    }
}
