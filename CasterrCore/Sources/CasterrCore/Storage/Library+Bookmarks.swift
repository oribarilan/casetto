import Foundation
import SwiftData

extension Library {
    // MARK: Bookmarks

    @discardableResult
    public func addBookmark(_ episode: EpisodeInfo, showTitle: String, at position: TimeInterval) throws -> UUID {
        let bookmark = Bookmark(
            episodeKey: episode.key.rawValue, position: max(position, 0), showTitle: showTitle,
            episodeTitle: episode.title, audioURL: episode.audioURL, createdAt: clock()
        )
        modelContext.insert(bookmark)
        try modelContext.save()
        return bookmark.id
    }

    public func setNote(_ note: String, for id: UUID) throws {
        try bookmark(id)?.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        try modelContext.save()
    }

    public func deleteBookmark(_ id: UUID) throws {
        guard let bookmark = try bookmark(id) else { return }
        modelContext.delete(bookmark)
        try modelContext.save()
    }

    /// Newest first. A non-empty `text` keeps bookmarks whose note, episode title, or show title contains it, ignoring case.
    public func bookmarks(matching text: String = "") throws -> [BookmarkInfo] {
        let term = text.trimmingCharacters(in: .whitespaces)
        return try modelContext.fetch(FetchDescriptor<Bookmark>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            .filter { term.isEmpty || [$0.note, $0.episodeTitle, $0.showTitle].contains { $0.localizedStandardContains(term) } }
            .map { BookmarkInfo(
                id: $0.id, episodeKey: EpisodeKey(rawValue: $0.episodeKey), position: $0.position, note: $0.note,
                createdAt: $0.createdAt, showTitle: $0.showTitle, episodeTitle: $0.episodeTitle, audioURL: $0.audioURL
            ) }
    }

    private func bookmark(_ id: UUID) throws -> Bookmark? {
        try modelContext.fetch(FetchDescriptor<Bookmark>(predicate: #Predicate { $0.id == id })).first
    }
}
