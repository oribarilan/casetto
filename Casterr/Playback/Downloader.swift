import CasterrCore
import Foundation

/// Downloads episodes in a background session that never uses cellular data, Personal Hotspot,
/// or Low Data Mode. Each task's description is its episode key, so running downloads
/// come back after a relaunch with no stored state.
final class Downloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    static let sessionID = "casterr.downloads"
    /// Posted after a finished download is saved.
    static let didSave = Notification.Name("casterr.downloadDidSave")

    let store: DownloadStore
    private var session: URLSession!

    init(store: DownloadStore) {
        self.store = store
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: Self.sessionID)
        config.allowsCellularAccess = false
        config.allowsExpensiveNetworkAccess = false
        config.allowsConstrainedNetworkAccess = false
        config.sessionSendsLaunchEvents = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    /// Episode keys with a download in progress.
    func running() async -> [EpisodeKey: URLSessionTask] {
        var running: [EpisodeKey: URLSessionTask] = [:]
        for task in await session.allTasks where task.state == .running || task.state == .suspended {
            if let key = task.taskDescription { running[EpisodeKey(rawValue: key)] = task }
        }
        return running
    }

    func start(_ key: EpisodeKey, from url: URL) {
        let task = session.downloadTask(with: url)
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
}
