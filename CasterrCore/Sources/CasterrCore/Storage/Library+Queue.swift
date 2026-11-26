import Foundation
import SwiftData

extension Library {
    // MARK: Latest move

    /// Each episode's place, latest move, and progress, read in one fetch, for long lists like a show page.
    /// Episodes the listener never touched are left out.
    public func snapshots(of keys: [EpisodeKey]) throws -> [EpisodeKey: EpisodeSnapshot] {
        let wanted = Set(keys.map(\.rawValue))
        var snapshots: [EpisodeKey: EpisodeSnapshot] = [:]
        for state in try modelContext.fetch(FetchDescriptor<EpisodeState>()) where wanted.contains(state.episodeKey) {
            snapshots[EpisodeKey(rawValue: state.episodeKey)] = EpisodeSnapshot(
                place: try? Place(storedPlace: state.place, archiveReason: state.archiveReason),
                move: state.moveReason.flatMap(MoveReason.init(stored:)).map(LastMove.init(reason:)),
                progress: state.progressSeconds
            )
        }
        return snapshots
    }

    public func lastMove(of key: EpisodeKey) throws -> LastMove? {
        guard let state = try state(key), let raw = state.moveReason, let reason = MoveReason(stored: raw) else { return nil }
        return LastMove(reason: reason)
    }

    // MARK: Queue

    /// Episode keys in play order. The first is Now Playing.
    public func queue() throws -> [EpisodeKey] {
        try states(in: .queue).map { EpisodeKey(rawValue: $0.episodeKey) }
    }

    /// The Queue as this device can show and play it: a shared file or an unfollowed show's episode
    /// queued on another device has no record here, so it's skipped and the others keep their order.
    public func playableQueue() throws -> [EpisodeKey] {
        let queued = try queue()
        let known = try knownEpisodeKeys(among: queued.map(\.rawValue))
        return queued.filter { known.contains($0.rawValue) }
    }

    /// The first `limit` playable Queue episodes, leaving out shared files, as downloads pick them.
    public func queueEpisodes(limit: Int) throws -> [EpisodeInfo] {
        let shared = ShowKey.shared.rawValue + "|"
        return try playableQueue().filter { !$0.rawValue.hasPrefix(shared) }.prefix(max(limit, 0))
            .compactMap { try episode($0) }
    }

    /// Moves a queued episode to `index` in the playable Queue, where hidden episodes don't count.
    public func movePlayable(_ key: EpisodeKey, to index: Int) throws {
        let others = try playableQueue().filter { $0 != key }
        let full = try queue().filter { $0 != key }
        let target: Int
        if index < others.count {
            target = full.firstIndex(of: others[max(index, 0)]) ?? 0
        } else {
            target = others.last.flatMap { full.firstIndex(of: $0) }.map { $0 + 1 } ?? full.count
        }
        try move(key, to: target)
    }

    /// The keys among `keys` that have an episode in the feed cache: the ones this device can show and play.
    private func knownEpisodeKeys(among keys: [String]) throws -> Set<String> {
        var descriptor = FetchDescriptor<EpisodeRecord>(predicate: #Predicate { keys.contains($0.key) })
        descriptor.propertiesToFetch = [\.key]
        return Set(try modelContext.fetch(descriptor).map(\.key))
    }

    /// Adds to the end. An episode already in the Queue keeps its position.
    public func addToQueue(_ key: EpisodeKey) throws {
        let state = try state(key, creating: true)!
        guard state.place != Place.queue.stored.place else { return }
        try relocate(state, to: .queue, reason: .listener)
        try modelContext.save()
    }

    /// Moves a queued episode to `index` (0 is Now Playing). Others keep their relative order.
    public func move(_ key: EpisodeKey, to index: Int) throws {
        var queued = try states(in: .queue)
        guard let from = queued.firstIndex(where: { $0.episodeKey == key.rawValue }) else { return }
        let state = queued.remove(at: from)
        queued.insert(state, at: min(max(index, 0), queued.count))
        renumber(queued)
        try modelContext.save()
    }

    /// Puts the episode first, adding it to the Queue if needed. Used when playback starts.
    public func moveToTop(_ key: EpisodeKey) throws {
        try relocate(state(key, creating: true)!, to: .queue, reason: .listener)
        try move(key, to: 0)
    }

    /// Removed like a dismissed Inbox episode, so its show page says "Removed". It keeps its progress.
    public func removeFromQueue(_ key: EpisodeKey) throws {
        guard let state = try state(key), state.place == Place.queue.stored.place else { return }
        try relocate(state, to: .archive(.dismissed), reason: .listener)
        try modelContext.save()
    }

    /// Play-next episodes go after Now Playing and after earlier play-next episodes.
    /// Right after Now Playing, the first episode this device has, and after earlier Play next episodes.
    func playNextIndex(in queued: [EpisodeState]) throws -> Int {
        let known = try knownEpisodeKeys(among: queued.map(\.episodeKey))
        guard let nowPlaying = queued.firstIndex(where: { known.contains($0.episodeKey) }) else { return queued.count }
        var index = nowPlaying + 1
        while index < queued.count, queued[index].moveReason == MoveReason.playNext.stored {
            index += 1
        }
        return index
    }

    // MARK: Episode state

    public func place(of key: EpisodeKey) throws -> Place? {
        guard let state = try state(key) else { return nil }
        return try Place(storedPlace: state.place, archiveReason: state.archiveReason)
    }

    public func progress(of key: EpisodeKey) throws -> TimeInterval {
        try state(key)?.progressSeconds ?? 0
    }

    func firstPlayedAt(of key: EpisodeKey) throws -> Date? {
        try state(key)?.firstPlayedAt
    }

    /// Records the first time playback started. Later starts change nothing.
    public func recordPlayStart(_ key: EpisodeKey) throws {
        let state = try state(key, creating: true)!
        guard state.firstPlayedAt == nil else { return }
        state.firstPlayedAt = clock()
        try modelContext.save()
    }

    public func setProgress(_ key: EpisodeKey, to seconds: TimeInterval) throws {
        try state(key, creating: true)!.progressSeconds = max(seconds, 0)
        try modelContext.save()
    }

    /// Moves the episode to the archive. If it was queued, it leaves the Queue.
    public func markPlayed(_ key: EpisodeKey) throws {
        try relocate(state(key, creating: true)!, to: .archive(.played), reason: .listener)
        try modelContext.save()
    }

    /// Resets progress. An archived episode ends up with no place; a queued one stays queued.
    public func markUnplayed(_ key: EpisodeKey) throws {
        guard let state = try state(key) else { return }
        if state.place == Place.archive(.played).stored.place {
            try relocate(state, to: nil, reason: .listener)
        }
        state.progressSeconds = 0
        try modelContext.save()
    }
}
