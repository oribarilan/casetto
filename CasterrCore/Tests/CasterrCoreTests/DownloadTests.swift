import Foundation
import Testing
@testable import CasterrCore

private let show = ShowKey(feedURL: URL(string: "https://example.com/feed")!)!

private func episode(_ n: Int) -> EpisodeKey {
    EpisodeKey(show: show, guid: "ep\(n)", audioURL: URL(string: "https://cdn.example.com/\(n).mp3")!)
}

private func stem(_ n: Int) -> String { DownloadStore.stem(for: episode(n)) }

private func temporaryStore() throws -> DownloadStore {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return DownloadStore(folder: folder)
}

private func temporaryFile() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try Data("audio".utf8).write(to: url)
    return url
}

struct DownloadStoreTests {
    private let audio = URL(string: "https://cdn.example.com/1.m4a?token=x")!

    @Test func fileNameIsTheKeyHashWithTheAudioExtension() throws {
        let store = try temporaryStore()
        let name = store.file(for: episode(1), audioURL: audio).lastPathComponent
        #expect(name == "\(stem(1)).m4a")
        #expect(stem(1).count == 64)
        #expect(stem(1) != stem(2))
    }

    @Test func missingExtensionDefaultsToMP3() throws {
        let store = try temporaryStore()
        let file = store.file(for: episode(1), audioURL: URL(string: "https://cdn.example.com/play?id=1")!)
        #expect(file.pathExtension == "mp3")
    }

    @Test func savedFileIsFoundListedAndDeleted() throws {
        let store = try temporaryStore()
        #expect(store.localFile(for: episode(1), audioURL: audio) == nil)
        try store.save(temporaryFile(), for: episode(1), audioURL: audio)
        #expect(store.localFile(for: episode(1), audioURL: audio) != nil)
        #expect(store.stems() == [stem(1)])
        store.delete(stem: stem(1))
        #expect(store.localFile(for: episode(1), audioURL: audio) == nil)
        #expect(store.stems().isEmpty)
    }

    @Test func savingAgainReplacesTheFile() throws {
        let store = try temporaryStore()
        try store.save(temporaryFile(), for: episode(1), audioURL: audio)
        try store.save(temporaryFile(), for: episode(1), audioURL: audio)
        #expect(store.stems() == [stem(1)])
    }
}

struct DownloadPlanTests {
    private let queue = (1...5).map(episode)

    @Test func startsTheTopOfTheQueueInOrder() {
        let plan = DownloadPlan.make(queue: queue, keep: 3, files: [], running: [])
        #expect(plan == DownloadPlan(start: [episode(1), episode(2), episode(3)]))
    }

    @Test func keepsWantedFilesAndRunningDownloads() {
        let plan = DownloadPlan.make(queue: queue, keep: 3, files: [stem(1)], running: [episode(2)])
        #expect(plan == DownloadPlan(start: [episode(3)]))
    }

    @Test func episodePushedOutOfRangeLosesItsFile() {
        let pushed = [episode(1), episode(3), episode(4), episode(2), episode(5)]
        let plan = DownloadPlan.make(queue: pushed, keep: 3, files: [stem(1), stem(2), stem(3)], running: [])
        #expect(plan == DownloadPlan(start: [episode(4)], delete: [stem(2)]))
    }

    @Test func runningDownloadNoLongerWantedIsCancelled() {
        let plan = DownloadPlan.make(queue: [episode(2)], keep: 3, files: [stem(2)], running: [episode(1)])
        #expect(plan == DownloadPlan(cancel: [episode(1)]))
    }

    @Test func offDeletesEverythingAndStartsNothing() {
        let plan = DownloadPlan.make(queue: queue, keep: 0, files: [stem(1), "stray"], running: [episode(2)])
        #expect(plan == DownloadPlan(cancel: [episode(2)], delete: [stem(1), "stray"]))
    }

    @Test func emptyQueueDeletesEveryFile() {
        let plan = DownloadPlan.make(queue: [], keep: 3, files: [stem(1)], running: [])
        #expect(plan == DownloadPlan(delete: [stem(1)]))
    }
}

struct DownloadCountSettingTests {
    @Test func defaultsToThreeAndChanges() async throws {
        let library = try Library.open(inMemory: true)
        #expect(try await library.downloadCount() == 3)
        try await library.setDownloadCount(0)
        #expect(try await library.downloadCount() == 0)
    }
}

struct DownloadStateTests {
    @Test func aFileOnThePhoneIsDownloaded() {
        #expect(DownloadState.of(downloaded: true, progress: .some(0.5), wanted: true, downloadsAllowed: false) == .downloaded)
    }

    @Test func aRunningDownloadShowsItsShare() {
        #expect(DownloadState.of(downloaded: false, progress: .some(0.456), wanted: true, downloadsAllowed: true) == .downloading(0.456))
        #expect(DownloadState.downloading(0.456).label == "Downloading 45%")
        #expect(DownloadState.downloading(0.999).label == "Downloading 99%")
    }

    @Test func aDownloadWithNoSizeShowsNoNumber() {
        #expect(DownloadState.of(downloaded: false, progress: .some(nil), wanted: true, downloadsAllowed: true) == .downloading(nil))
        #expect(DownloadState.downloading(nil).label == "Downloading")
    }

    @Test func aWantedEpisodeWaitsOffWiFi() {
        #expect(DownloadState.of(downloaded: false, progress: nil, wanted: true, downloadsAllowed: false) == .waiting)
        #expect(DownloadState.waiting.label == "Waiting for Wi-Fi")
    }

    @Test func theLoadedEpisodeNeverWaitsForWiFi() {
        #expect(DownloadState.of(downloaded: false, progress: nil, wanted: true, downloadsAllowed: false, loaded: true) == nil)
    }

    @Test func theLoadedEpisodeKeepsItsDownloadWords() {
        #expect(DownloadState.of(downloaded: true, progress: nil, wanted: true, downloadsAllowed: false, loaded: true) == .downloaded)
        #expect(DownloadState.of(downloaded: false, progress: .some(0.3), wanted: true, downloadsAllowed: false, loaded: true) == .downloading(0.3))
        #expect(DownloadState.of(downloaded: false, progress: nil, wanted: true, downloadsAllowed: true, loaded: true) == .downloading(0))
    }

    @Test func aWantedEpisodeOnWiFiIsAboutToDownload() {
        #expect(DownloadState.of(downloaded: false, progress: nil, wanted: true, downloadsAllowed: true) == .downloading(0))
    }

    @Test func anEpisodeOutsideTheKeptOnesSaysNothing() {
        #expect(DownloadState.of(downloaded: false, progress: nil, wanted: false, downloadsAllowed: false) == nil)
    }
}

