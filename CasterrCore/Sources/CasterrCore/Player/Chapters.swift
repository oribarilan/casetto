import Foundation

/// A named part of an episode, from the audio file or the show notes.
public struct Chapter: Equatable, Sendable {
    public let start: TimeInterval
    public let title: String
    /// Image bytes from the audio file. Nil for show-notes chapters.
    public let artwork: Data?

    public init(start: TimeInterval, title: String, artwork: Data? = nil) {
        self.start = start
        self.title = title
        self.artwork = artwork
    }
}

/// How far playback is through each chapter. A chapter ends where the next starts; the last ends at the
/// episode's duration, and without one it shows no progress.
public struct ChapterProgress: Equatable, Sendable {
    /// The playing chapter's index, nil before the first chapter.
    public let current: Int?
    /// Per chapter, from 0 (not started) to 1 (played).
    public let fractions: [Double]
    /// Whole minutes left in the playing chapter, rounded up. Nil when its end is unknown.
    public let minutesLeft: Int?

    public init(chapters: [Chapter], position: TimeInterval, duration: TimeInterval?) {
        let current = chapters.lastIndex { $0.start <= position }
        self.current = current
        func end(_ index: Int) -> TimeInterval? {
            index + 1 < chapters.count ? chapters[index + 1].start : duration
        }
        fractions = chapters.indices.map { index in
            guard let current, index <= current else { return 0 }
            if index < current { return 1 }
            guard let end = end(index), end > chapters[index].start else { return 0 }
            return min(max((position - chapters[index].start) / (end - chapters[index].start), 0), 1)
        }
        minutesLeft = current.flatMap(end).map { max(1, Int((($0 - position) / 60).rounded(.up))) }
    }
}

/// Finds a chapter list in show notes: lines that start with a time, such as "5:51 ג׳נסן שובב".
/// Strict on purpose, so a time mentioned in prose never becomes a chapter.
public enum ShowNotesChapters {
    /// At least two entries in increasing order, all before `duration` when it's known; otherwise none.
    public static func parse(_ notes: String, duration: TimeInterval?) -> [Chapter] {
        var chapters: [Chapter] = []
        for line in lines(of: notes) {
            guard let chapter = chapter(in: line) else { continue }
            // A repeated or out-of-order entry is dropped, which also removes a list given twice.
            if let last = chapters.last, chapter.start <= last.start { continue }
            if let duration, chapter.start >= duration { return [] }
            chapters.append(chapter)
        }
        return chapters.count >= 2 ? chapters : []
    }

    private static func lines(of html: String) -> [String] {
        let broken = html.replacing(/(?i)<br\s*\/?>|<\/p>|<\/li>|<\/div>/, with: "\n")
        let text = HTMLText.decodingEntities(broken.replacing(/<[^>]+>/, with: ""))
        return text.split(whereSeparator: \.isNewline).map(String.init)
    }

    /// "(1:02:03) Title", "[12:30] - Title", "0:00 Title". The title needs at least one letter.
    private static func chapter(in line: String) -> Chapter? {
        let pattern = /^\s*[\(\[]?(?:(\d{1,2}):)?(\d{1,2}):(\d{2})[\)\]]?\s*[-–—:|]?\s*(.+?)\s*$/
        guard let match = line.wholeMatch(of: pattern),
              let minutes = Int(match.2), let seconds = Int(match.3), seconds < 60
        else { return nil }
        let hours = match.1.flatMap { Int($0) } ?? 0
        if match.1 != nil, minutes >= 60 { return nil }
        let title = String(match.4)
        guard title.contains(where: \.isLetter) else { return nil }
        return Chapter(start: TimeInterval(hours * 3600 + minutes * 60 + seconds), title: title)
    }
}

enum HTMLText {
    /// The text of an HTML description on one line, or nil when nothing is left.
    static func plain(_ html: String?) -> String? {
        guard let html else { return nil }
        let text = decodingEntities(html.replacing(/<[^>]+>/, with: " "))
            .replacing(/\s+/, with: " ").trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }

    static func decodingEntities(_ text: String) -> String {
        var text = text
        for (entity, character) in ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&apos;": "'", "&nbsp;": " "] {
            text = text.replacing(entity, with: character)
        }
        return text
    }
}
