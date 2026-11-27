import Foundation
import Testing

@testable import CasterrCore

struct FolderSizeTests {
    @Test func addsTheFilesInAFolder() throws {
        let folder = URL.temporaryDirectory.appending(path: "size-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        try Data(count: 1000).write(to: folder.appending(path: "a"))
        try Data(count: 500).write(to: folder.appending(path: "b"))
        #expect(FileManager.default.size(ofFolder: folder) == 1500)
    }

    @Test func missingFolderIsZero() {
        #expect(
            FileManager.default.size(ofFolder: .temporaryDirectory.appending(path: "none-\(UUID().uuidString)")) == 0)
    }
}
