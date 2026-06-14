import SwiftData
import SwiftUI

@main
struct MemoPingApp: App {
    private let modelContainer = MemoDataStore.shared.container

    init() {
        MemoPingAppShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(modelContainer)
    }
}
