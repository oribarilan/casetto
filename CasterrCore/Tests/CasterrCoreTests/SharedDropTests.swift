import Foundation
import Testing
@testable import CasterrCore

struct SharedDropTests {
    private func drop() throws -> SharedDrop {
        SharedDrop(inbox: FileManager.default.temporaryDirectory.appending(path: "inbox-\(UUID().uuidString)"))
    }

    @Test func aDroppedFileComesBackWithItsNote() throws {
        let drop = try drop()
        let file = FileManager.default.temporaryDirectory.appending(path: "memo-\(UUID().uuidString).m4a")
        try Data("audio".utf8).write(to: file)
        try drop.drop(.file("Voice memo 12.m4a", title: "Voice memo 12"), file: file)
        let items = drop.pending()
        #expect(items.count == 1)
        #expect(items[0].note == .file("Voice memo 12.m4a", title: "Voice memo 12"))
        #expect(FileManager.default.fileExists(atPath: items[0].folder.appending(path: "Voice memo 12.m4a").path(percentEncoded: false)))
        drop.remove(items[0].folder)
        #expect(drop.pending().isEmpty)
    }

    @Test func aLinkNoteRoundTrips() throws {
        let drop = try drop()
        let episode = DirectoryEpisode(title: "Two Hot Streaks", feedURL: URL(string: "https://cdn.atp.fm/rss/public")!,
                                       guid: "t3vbwlfpueremdht", audioURL: nil)
        try drop.drop(.link(episode))
        #expect(drop.pending().map(\.note) == [.link(episode)])
    }

    @Test func aFolderWithoutANoteIsIgnored() throws {
        let drop = try drop()
        try FileManager.default.createDirectory(at: drop.inbox.appending(path: "half-written"), withIntermediateDirectories: true)
        #expect(drop.pending().isEmpty)
    }
}

struct SharedStoreTests {
    @Test func savesFindsAndDeletesByAddress() throws {
        let store = SharedStore(folder: FileManager.default.temporaryDirectory.appending(path: "shared-\(UUID().uuidString)"))
        let source = FileManager.default.temporaryDirectory.appending(path: "memo-\(UUID().uuidString).m4a")
        try Data("audio".utf8).write(to: source)
        let address = SharedStore.audioURL(id: "abc", fileExtension: "m4a")
        #expect(address.absoluteString == "casterr-shared:///abc.m4a")
        #expect(store.file(for: address) == nil)
        try store.save(source, as: address)
        #expect(store.file(for: address)?.lastPathComponent == "abc.m4a")
        #expect(store.file(for: URL(string: "https://example.com/abc.m4a")!) == nil)
        store.delete(address)
        #expect(store.file(for: address) == nil)
    }
}
