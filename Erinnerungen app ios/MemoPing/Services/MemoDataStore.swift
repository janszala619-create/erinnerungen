import Foundation
import SwiftData

final class MemoDataStore {
    static let shared = MemoDataStore()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            MemoItem.self,
            MemoCategoryItem.self
        ])

        do {
            let configuration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("MemoPing: ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }
}
