import SwiftUI

@main
struct CasterrApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: AppModel = {
        // UI tests launch with an empty in-memory library.
        let inMemory = ProcessInfo.processInfo.arguments.contains("-uiTesting")
        return try! AppModel(inMemory: inMemory)
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(model.player)
        }
        .backgroundTask(.appRefresh(AppModel.refreshTaskID)) { [model] in
            await model.backgroundRefresh()
        }
        // The session already exists; declaring it lets iOS relaunch the app to deliver finished downloads.
        .backgroundTask(.urlSession(Downloader.sessionID)) {}
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: Task { await model.appBecameActive() }
            case .background: Task { await model.appWentToBackground() }
            default: break
            }
        }
    }
}
