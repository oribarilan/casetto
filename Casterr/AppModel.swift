import AVFoundation
import CasterrCore
import NowPlaying
import Observation

/// Owns the app's long-lived objects and reacts to audio-session and lifecycle events.
@MainActor @Observable
final class AppModel {
    let library: Library
    let feeds: FeedService
    let player: Player
    /// Bumped after every change to stored data, so views know to reload.
    private(set) var revision = 0
    @ObservationIgnored private var nowPlaying: MediaSession<NowPlayingBridge>?
    @ObservationIgnored private var eventTasks: [Task<Void, Never>] = []

    init(inMemory: Bool = false) throws {
        library = try Library.open(inMemory: inMemory)
        feeds = FeedService(library: library)
        player = Player(library: library, engine: AVPlayerEngine())
        startNowPlaying()
        observeAudioSession()
    }

    func appBecameActive() async {
        await refresh()
    }

    func refresh() async {
        try? await feeds.refreshAll()
        revision += 1
    }

    /// Runs a change and tells views to reload. Returns the error message, if any.
    @discardableResult
    func change(_ work: () async throws -> Void) async -> String? {
        defer { revision += 1 }
        do {
            try await work()
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func appWentToBackground() async {
        try? await player.saveProgress()
    }

    private func startNowPlaying() {
        let session = MediaSession(NowPlayingBridge(player: player))
        nowPlaying = session
        Task { try? await session.requestToBecomeSystemPrimary() }
    }

    /// Pauses for calls and other interruptions, resumes when the system says to,
    /// and pauses when headphones disconnect.
    private func observeAudioSession() {
        let center = NotificationCenter.default
        let player = player
        eventTasks = [
            Task {
                for await note in center.notifications(named: AVAudioSession.didBecomeInactiveNotification) {
                    let context = note.userInfo?[AVAudioSession.deactivationContextKey] as? AVAudioSession.DeactivationContext
                    if context?.source == .system { try? await player.pause() }
                }
            },
            Task {
                for await note in center.notifications(named: AVAudioSession.resumptionRecommendationNotification) {
                    let context = note.userInfo?[AVAudioSession.resumptionContextKey] as? AVAudioSession.ResumptionContext
                    if context?.recommendation == .shouldResume { try? await player.resume() }
                }
            },
            Task {
                for await note in center.notifications(named: AVAudioSession.routeChangeNotification) {
                    guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                          AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { continue }
                    try? await player.pause()
                }
            },
        ]
    }
}
