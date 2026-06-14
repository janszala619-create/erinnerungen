import SwiftData
import SwiftUI

@main
struct MemoPingApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([MemoItem.self])

        do {
            let configuration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private(ICloudSyncService.cloudKitContainerIdentifier)
            )

            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            #if DEBUG
            print("MemoPing: CloudKit ModelContainer konnte nicht erstellt werden. Lokaler Fallback: \(error)")
            #endif

            let localConfiguration = ModelConfiguration(schema: schema)
            do {
                return try ModelContainer(for: schema, configurations: [localConfiguration])
            } catch {
                fatalError("MemoPing: ModelContainer konnte nicht erstellt werden: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(modelContainer)
    }
}
