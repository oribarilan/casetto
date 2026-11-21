import Foundation

/// Files shared to Casterr. Episodes refer to them by a stable `casterr-shared:///<name>` address,
/// because the app container's path can change across a restore.
public struct SharedStore: Sendable {
    public static let scheme = "casterr-shared"
    public let folder: URL

    public init(folder: URL) {
        self.folder = folder
    }

    /// `Application Support/Shared`, excluded from iCloud backup like downloads.
    public static func standard() throws -> SharedStore {
        var folder = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        ).appending(path: "Shared", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try folder.setResourceValues(values)
        return SharedStore(folder: folder)
    }

    /// The address for a new shared file. Keeps the extension, which `AVPlayer` uses to detect the type.
    public static func audioURL(id: String, fileExtension: String) -> URL {
        URL(string: "\(scheme):///\(id).\(fileExtension.isEmpty ? "m4a" : fileExtension)")!
    }

    /// The file behind a shared address, if it's on this device.
    public func file(for audioURL: URL) -> URL? {
        guard audioURL.scheme == Self.scheme else { return nil }
        let url = folder.appending(path: audioURL.lastPathComponent)
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) ? url : nil
    }

    /// Moves the shared file into place under its address.
    public func save(_ source: URL, as audioURL: URL) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: source, to: folder.appending(path: audioURL.lastPathComponent))
    }

    public func delete(_ audioURL: URL) {
        guard audioURL.scheme == Self.scheme else { return }
        try? FileManager.default.removeItem(at: folder.appending(path: audioURL.lastPathComponent))
    }

    /// Cassy as a picture: the art of the Shared with Casterr show.
    public var cassyArt: URL { folder.appending(path: "cassy.png") }
}
