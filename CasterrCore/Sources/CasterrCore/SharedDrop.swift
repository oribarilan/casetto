import Foundation

/// One item shared to Casterr, as the share extension leaves it for the app.
public struct SharedNote: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable { case file, link }

    public var kind: Kind
    /// What the confirmation showed: the file's title tag or name, or the episode's title from Apple.
    public var title: String
    /// For a file: its name in the item's folder.
    public var fileName: String?
    /// For a link: what Apple's lookup found.
    public var episode: DirectoryEpisode?

    public static func file(_ fileName: String, title: String) -> SharedNote {
        SharedNote(kind: .file, title: title, fileName: fileName)
    }

    public static func link(_ episode: DirectoryEpisode) -> SharedNote {
        SharedNote(kind: .link, title: episode.title, episode: episode)
    }
}



/// The folder in the App Group where the extension drops shared items and the app picks them up.
/// Each item is a folder holding `item.json` (written last) and, for a file, the file itself.
public struct SharedDrop: Sendable {
    public static let appGroup = "group.com.oribarilan.Casterr"
    /// The Darwin notification the extension posts so a running app picks items up right away.
    public static let notification = "com.oribarilan.Casterr.shared"

    public let inbox: URL

    public init(inbox: URL) {
        self.inbox = inbox
    }

    /// The App Group's inbox, or nil when the App Group isn't available.
    public static func standard() -> SharedDrop? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            .map { SharedDrop(inbox: $0.appending(path: "Inbox", directoryHint: .isDirectory)) }
    }

    /// Leaves an item: copies the file, if any, then writes the note, so a half-written item is never picked up.
    public func drop(_ note: SharedNote, file: URL? = nil) throws {
        let folder = inbox.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if let file, let name = note.fileName {
            try FileManager.default.copyItem(at: file, to: folder.appending(path: name))
        }
        try JSONEncoder().encode(note).write(to: folder.appending(path: "item.json"), options: .atomic)
    }

    /// Items with a note, oldest first.
    public func pending() -> [(folder: URL, note: SharedNote)] {
        let folders = (try? FileManager.default.contentsOfDirectory(
            at: inbox, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)) ?? []
        return folders
            .compactMap { folder -> (URL, SharedNote, Date)? in
                guard let data = try? Data(contentsOf: folder.appending(path: "item.json")),
                      let note = try? JSONDecoder().decode(SharedNote.self, from: data) else { return nil }
                let created = (try? folder.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return (folder, note, created)
            }
            .sorted { $0.2 < $1.2 }
            .map { ($0.0, $0.1) }
    }

    public func remove(_ folder: URL) {
        try? FileManager.default.removeItem(at: folder)
    }
}
