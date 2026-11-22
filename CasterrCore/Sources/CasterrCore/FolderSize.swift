import Foundation

extension FileManager {
    /// Bytes in the files directly inside `folder`, or 0 when it doesn't exist.
    public func size(ofFolder folder: URL) -> Int {
        let files = (try? contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return files.reduce(0) { $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
    }
}
