import Foundation

/// Bookmarks as a Markdown file, for Obsidian, Notes, or any notes app.
public enum BookmarkMarkdown {
    /// `bookmarks` are one episode's; they're listed in position order.
    public static func render(_ bookmarks: [BookmarkInfo]) -> String {
        guard let first = bookmarks.first else { return "" }
        var lines = ["# \(first.episodeTitle)", "", first.showTitle]
        if let audio = first.audioURL { lines.append("<\(audio.absoluteString)>") }
        lines.append("")
        for bookmark in bookmarks.sorted(by: { $0.position < $1.position }) {
            let time = timestamp(bookmark.position)
            lines.append(bookmark.note.isEmpty ? "- \(time)" : "- \(time) \(bookmark.note)")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Several episodes in one file, in the given order. `episodes` holds one array per episode.
    public static func render(episodes: [[BookmarkInfo]]) -> String {
        episodes.map(render).joined(separator: "\n")
    }

    /// One episode's file name, or "Bookmarks.md" for several.
    public static func fileName(episodes: [[BookmarkInfo]]) -> String {
        episodes.count == 1 ? fileName(episodes[0]) : "Bookmarks.md"
    }

    /// "Show - Episode.md", without characters that file systems reject.
    public static func fileName(_ bookmarks: [BookmarkInfo]) -> String {
        let name = bookmarks.first.map { "\($0.showTitle) - \($0.episodeTitle)" } ?? "Bookmarks"
        let safe = name.map { "/\\:*?\"<>|".contains($0) ? "-" : $0 }
        return String(safe).trimmingCharacters(in: .whitespaces) + ".md"
    }

    /// 12:34 or 1:02:03.
    static func timestamp(_ seconds: TimeInterval) -> String {
        let total = Int(max(seconds, 0))
        let (h, m, s) = (total / 3600, total % 3600 / 60, total % 60)
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
