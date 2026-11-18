import AVFoundation
import CasterrCore

/// Streams one episode at a time with AVPlayer. The Queue lives in `Library`, not here.
@MainActor
final class AVPlayerEngine: AudioEngine {
    var onTime: ((TimeInterval, TimeInterval?) -> Void)?
    var onEnd: (() -> Void)?
    var onFailure: ((any Error) -> Void)?

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var notificationTasks: [Task<Void, Never>] = []

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 10), queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated { self?.reportTime(time) }
        }
    }

    func load(_ url: URL, at position: TimeInterval) {
        let item = AVPlayerItem(url: url)
        item.audioTimePitchAlgorithm = .timeDomain
        observe(item)
        player.replaceCurrentItem(with: item)
        if position > 0 { seek(to: position) }
    }

    func play(rate: Double) {
        try? AVAudioSession.sharedInstance().setActive(true)
        player.playImmediately(atRate: Float(rate))
    }

    func pause() {
        player.pause()
    }

    func seek(to position: TimeInterval) {
        player.seek(to: CMTime(seconds: position, preferredTimescale: 600))
    }

    private func reportTime(_ time: CMTime) {
        guard let item = player.currentItem else { return }
        let duration = item.duration.isNumeric ? item.duration.seconds : nil
        onTime?(time.seconds, duration)
    }

    private func observe(_ item: AVPlayerItem) {
        notificationTasks.forEach { $0.cancel() }
        statusObservation = item.observe(\.status) { [weak self] item, _ in
            guard item.status == .failed else { return }
            let error = item.error ?? URLError(.unknown)
            Task { @MainActor in self?.onFailure?(error) }
        }
        let center = NotificationCenter.default
        notificationTasks = [
            Task { [weak self] in
                for await _ in center.notifications(named: AVPlayerItem.didPlayToEndTimeNotification, object: item) {
                    self?.onEnd?()
                }
            },
            Task { [weak self] in
                for await note in center.notifications(named: AVPlayerItem.failedToPlayToEndTimeNotification, object: item) {
                    let error = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? any Error
                    self?.onFailure?(error ?? URLError(.unknown))
                }
            },
        ]
    }
}
