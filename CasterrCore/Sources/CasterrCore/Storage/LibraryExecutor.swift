import Foundation
import SwiftData

/// Runs the library's work on its own queue. SwiftData's default executor runs each job on the thread
/// that asks for it, so the app's calls from the main actor would read and save on the main thread
/// and stall animations.
final class LibraryExecutor: SerialModelExecutor, @unchecked Sendable {
    let modelContext: ModelContext
    private let queue = DispatchQueue(label: "sh.oribi.Casterr.library", qos: .userInitiated)

    init(container: ModelContainer) {
        modelContext = queue.sync { ModelContext(container) }
    }

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        queue.async { job.runSynchronously(on: executor) }
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}
