import Foundation

/// The last top shows of each country, kept in a folder in the app's caches so Find Shows opens with them at once.
/// A cache: failures to read or write mean no saved list, never an error.
public struct SavedCharts: Sendable {
    let folder: URL

    public init(folder: URL = .cachesDirectory.appending(path: "Charts")) {
        self.folder = folder
    }

    /// The shows saved for `country`, or nil when none are.
    public func shows(for country: String) -> [DirectoryShow]? {
        (try? Data(contentsOf: file(country))).flatMap { try? JSONDecoder().decode([DirectoryShow].self, from: $0) }
    }

    public func save(_ shows: [DirectoryShow], for country: String) {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? JSONEncoder().encode(shows).write(to: file(country), options: .atomic)
    }

    /// Bytes on disk.
    public var size: Int { FileManager.default.size(ofFolder: folder) }

    public func clear() {
        try? FileManager.default.removeItem(at: folder)
    }

    private func file(_ country: String) -> URL {
        folder.appending(path: "\(country.lowercased().filter(\.isLetter)).json")
    }
}
