import SwiftData
import SwiftUI

@main
struct MemoPingApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([MemoItem.self])

        do {
            let configuration: ModelConfiguration

            if ICloudSyncService.isCloudKitModelContainerEnabled {
                configuration = ModelConfiguration(
                    schema: schema,
                    cloudKitDatabase: .private(ICloudSyncService.cloudKitContainerIdentifier)
                )
            } else {
                configuration = ModelConfiguration(schema: schema)

                #if DEBUG
                print("MemoPing: Keine CloudKit-Entitlements gefunden. Starte mit lokalem SwiftData-Container.")
                #endif
            }

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
