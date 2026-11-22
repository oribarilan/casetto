import CryptoKit
import Foundation

/// Downloaded episode files. A file exists only once its download is complete,
/// so the folder's contents are the only download state.
public struct DownloadStore: Sendable {
    public let folder: URL

    public init(folder: URL) {
        self.folder = folder
    }

    /// `Application Support/Downloads`, excluded from iCloud backup.
    public static func standard() throws -> DownloadStore {
        var folder = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        ).appending(path: "Downloads", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try folder.setResourceValues(values)
        return DownloadStore(folder: folder)
    }

    /// The file name without its extension: the SHA-256 hex of the episode key.
    public static func stem(for key: EpisodeKey) -> String {
        SHA256.hash(data: Data(key.rawValue.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Where the episode's file goes. Keeps the audio URL's extension, which `AVPlayer` uses to detect the type.
    public func file(for key: EpisodeKey, audioURL: URL) -> URL {
        let ext = audioURL.pathExtension.isEmpty ? "mp3" : audioURL.pathExtension
        return folder.appending(path: "\(Self.stem(for: key)).\(ext)")
    }

    /// The episode's file, if its download is complete.
    public func localFile(for key: EpisodeKey, audioURL: URL) -> URL? {
        let url = file(for: key, audioURL: audioURL)
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) ? url : nil
    }

    /// Moves a finished download into place, replacing any older file.
    public func save(_ downloaded: URL, for key: EpisodeKey, audioURL: URL) throws {
        let destination = file(for: key, audioURL: audioURL)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: downloaded, to: destination)
    }

    /// Bytes of downloaded files.
    public var size: Int { FileManager.default.size(ofFolder: folder) }

    /// The stems of the files in the folder.
    public func stems() -> [String] {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return files.map { $0.deletingPathExtension().lastPathComponent }
    }

    /// Deletes every file with this stem.
    public func delete(stem: String) {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.deletingPathExtension().lastPathComponent == stem {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
