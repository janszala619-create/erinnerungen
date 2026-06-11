import SwiftData
import SwiftUI

@main
struct MemoPingApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: MemoItem.self)
    }
}
