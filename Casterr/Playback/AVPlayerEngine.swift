import AVFoundation
import CasterrCore
import os

/// Streams one episode at a time with AVPlayer. The Queue lives in `Library`, not here.
@MainActor
final class AVPlayerEngine: AudioEngine {
    var onTime: ((TimeInterval, TimeInterval?) -> Void)?
    var onEnd: (() -> Void)?
    var onFailure: ((any Error) -> Void)?
    var onChapters: ((URL, [Chapter]) -> Void)?

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var notificationTasks: [Task<Void, Never>] = []
    private var playRequest = 0
    /// Where the latest seek is going, until it lands. Time reports use it meanwhile, so the slider doesn't
    /// jump back to the old spot between the seeks of a drag.
    private var seekTarget: CMTime?
    private var seekRequest = 0
    private var tap: AudioTap?
    /// Remembered so each new item's tap starts boosted or not.
    private var voiceBoost = false
    /// Remembered so each new item's tap knows how much of the episode each played frame covers.
    private var rate = 1.0
    private let log = Logger(subsystem: "sh.oribi.Casterr", category: "audioTap")
    private let chapterLog = Logger(subsystem: "sh.oribi.Casterr", category: "chapters")

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 10), queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated { self?.reportTime(time) }
        }
    }

    func load(_ url: URL, at position: TimeInterval) {
        // A downloaded file opens with precise timing, so seeks land where they report (VBR MP3s can drift otherwise).
        let item = AVPlayerItem(
            asset: AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: url.isFileURL]))
        item.audioTimePitchAlgorithm = .timeDomain
        observe(item)
        seekTarget = nil
        player.replaceCurrentItem(with: item)
        if position > 0 { seek(to: position, exact: false) }
    }

    /// Activates the audio session off the main thread, then plays, unless a newer play or pause came first.
    func play(rate: Double) {
        self.rate = rate
        tap?.setRate(rate)
        playRequest += 1
        let request = playRequest
        Task {
            _ = try? await AVAudioSession.sharedInstance().activate(options: [])
            guard request == playRequest else { return }
            player.playImmediately(atRate: Float(rate))
        }
    }

    func pause() {
        playRequest += 1
        player.pause()
        // The periodic time can be a second old; Back a Beat needs the exact pause point.
        reportTime(player.currentTime())
    }

    func seek(to position: TimeInterval, exact: Bool) {
        let target = CMTime(seconds: position, preferredTimescale: 600)
        seekRequest += 1
        let request = seekRequest
        seekTarget = target
        let tolerance = exact ? CMTime.zero : CMTime.positiveInfinity
        player.seek(to: target, toleranceBefore: tolerance, toleranceAfter: tolerance) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.seekRequest == request else { return }
                self.seekTarget = nil
            }
        }
    }

    func loudness(from start: TimeInterval, to end: TimeInterval) -> [Loudness] {
        let readings = tap?.loudness(from: start, to: end) ?? []
        log.debug("Back a Beat heard \(readings.count) readings from \(start) to \(end)")
        return readings
    }

    func setVoiceBoost(_ isOn: Bool) {
        voiceBoost = isOn
        tap?.setVoiceBoost(isOn)
        guard isOn else { return }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard let self, let tap = self.tap else { return }
            if tap.canBoost {
                self.log.debug("Voice boost compression \(tap.compressionAmount) dB")
            } else {
                self.log.debug("Voice boost can't use this audio format; it plays unboosted")
            }
        }
    }

    private func attachTap(to item: AVPlayerItem) {
        guard item === player.currentItem, item.audioMix == nil else { return }
        let tap = AudioTap()
        tap.setVoiceBoost(voiceBoost)
        tap.setRate(rate)
        self.tap = tap
        Task {
            guard let track = try? await item.asset.loadTracks(withMediaType: .audio).first else { return }
            item.audioMix = tap.audioMix(for: track)
        }
    }

    /// Reads the chapters embedded in the file. AVFoundation returns MP3 chapters only for the locale
    /// it reports (often "und"), not for a preferred language.
    private func loadChapters(of item: AVPlayerItem) {
        guard item === player.currentItem, let asset = item.asset as? AVURLAsset else { return }
        let url = asset.url
        Task {
            guard let locale = try? await asset.load(.availableChapterLocales).first,
                let groups = try? await asset.loadChapterMetadataGroups(
                    withTitleLocale: locale, containingItemsWithCommonKeys: [.commonKeyArtwork])
            else { return }
            var chapters: [Chapter] = []
            for (index, group) in groups.enumerated() {
                let title = try? await AVMetadataItem.metadataItems(
                    from: group.items, filteredByIdentifier: .commonIdentifierTitle
                ).first?.load(.stringValue)
                let artwork = try? await AVMetadataItem.metadataItems(
                    from: group.items, filteredByIdentifier: .commonIdentifierArtwork
                ).first?.load(.dataValue)
                chapters.append(
                    Chapter(
                        start: group.timeRange.start.seconds, title: title ?? "Chapter \(index + 1)", artwork: artwork))
            }
            chapterLog.debug(
                "The file has \(chapters.count) chapters, \(chapters.filter { $0.artwork != nil }.count) with pictures")
            guard item === player.currentItem, !chapters.isEmpty else { return }
            onChapters?(url, chapters)
        }
    }

    private func reportTime(_ time: CMTime) {
        guard let item = player.currentItem else { return }
        let duration = item.duration.isNumeric ? item.duration.seconds : nil
        onTime?((seekTarget ?? time).seconds, duration)
    }

    private func observe(_ item: AVPlayerItem) {
        for task in notificationTasks { task.cancel() }
        statusObservation = item.observe(\.status) { [weak self] item, _ in
            if item.status == .readyToPlay {
                Task { @MainActor in
                    self?.attachTap(to: item)
                    self?.loadChapters(of: item)
                }
                return
            }
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
                for await note in center.notifications(
                    named: AVPlayerItem.failedToPlayToEndTimeNotification, object: item)
                {
                    let error = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? any Error
                    self?.onFailure?(error ?? URLError(.unknown))
                }
            },
        ]
    }
}
