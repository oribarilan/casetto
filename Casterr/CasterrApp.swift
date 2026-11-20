import SwiftUI

@main
struct CasterrApp: App {
    @Environment(\.scenePhase) private var scenePhase
    // Shared, so the CarPlay scene uses the same library and player.
    @State private var model = AppModel.shared

    init() {
        Theme.apply()
    }

    var body: some Scene {
        WindowGroup {
            // Set at the root so sheets and full-screen covers get the tint and rounded type too.
            RootView()
                .tint(.tangerine)
                .fontDesign(.rounded)
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
