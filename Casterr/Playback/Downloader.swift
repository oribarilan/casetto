import CasterrCore
import Foundation
import Synchronization

/// Downloads episodes in a background session that never uses cellular data, Personal Hotspot,
/// or Low Data Mode, and, when the listener asks for one episode, in a second session that may use any network.
/// Each task's description is its episode key, so running downloads come back after a relaunch with no stored state.
final class Downloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    static let sessionID = "casterr.downloads"
    static let cellularSessionID = "casterr.downloads.cellular"
    /// Posted after a finished download is saved.
    static let didSave = Notification.Name("casterr.downloadDidSave")

    let store: DownloadStore
    /// Hears each running download's share done (nil when the server sent no size) and its size in bytes,
    /// and nil-nil when it ends. Called on the session's queue. Set it once, before downloads start.
    var onProgress: (@Sendable (EpisodeKey, Double??, Int64?) -> Void)?
    private var session: URLSession!
    private var cellularSession: URLSession!
    /// Episodes moved to the cellular session, whose cancelled Wi-Fi task must not end their progress.
    private let movedToCellular = Mutex<Set<String>>([])

    init(store: DownloadStore) {
        self.store = store
        super.init()
        session = makeSession(Self.sessionID, anyNetwork: false)
        cellularSession = makeSession(Self.cellularSessionID, anyNetwork: true)
    }

    private func makeSession(_ id: String, anyNetwork: Bool) -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: id)
        config.allowsCellularAccess = anyNetwork
        config.allowsExpensiveNetworkAccess = anyNetwork
        config.allowsConstrainedNetworkAccess = anyNetwork
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    /// Episode keys with a download in progress, in either session.
    func running() async -> [EpisodeKey: URLSessionTask] {
        var running: [EpisodeKey: URLSessionTask] = [:]
        for session in [session!, cellularSession!] {
            for task in await session.allTasks where task.state == .running || task.state == .suspended {
                if let key = task.taskDescription { running[EpisodeKey(rawValue: key)] = task }
            }
        }
        return running
    }

    func start(_ key: EpisodeKey, from url: URL) {
        let task = session.downloadTask(with: url)
        task.taskDescription = key.rawValue
        task.resume()
    }

    /// Downloads one episode on any network, replacing its download that waits for Wi-Fi.
    func startOnCellular(_ key: EpisodeKey, from url: URL) async {
        movedToCellular.withLock { _ = $0.insert(key.rawValue) }
        for task in await session.allTasks where task.taskDescription == key.rawValue { task.cancel() }
        let task = cellularSession.downloadTask(with: url)
        task.taskDescription = key.rawValue
        task.resume()
    }

    // MARK: URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // iOS deletes `location` when this method returns, so move the file now.
        guard let key = downloadTask.taskDescription, let audioURL = downloadTask.originalRequest?.url,
              let response = downloadTask.response as? HTTPURLResponse, (200..<300).contains(response.statusCode)
        else { return }
        try? store.save(location, for: EpisodeKey(rawValue: key), audioURL: audioURL)
        NotificationCenter.default.post(name: Self.didSave, object: nil)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let key = downloadTask.taskDescription else { return }
        let size = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : nil
        let share = size.map { Double(totalBytesWritten) / Double($0) }
        onProgress?(EpisodeKey(rawValue: key), .some(share), size)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        guard let key = task.taskDescription else { return }
        let moved = movedToCellular.withLock { moved in
            if session === cellularSession { moved.remove(key) }
            return moved.contains(key)
        }
        if session === self.session, moved { return }
        onProgress?(EpisodeKey(rawValue: key), nil, nil)
    }
}
