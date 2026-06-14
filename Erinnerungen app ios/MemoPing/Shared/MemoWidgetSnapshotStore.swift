import Foundation

struct MemoWidgetReminderSnapshot: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var dueDate: Date
    var isCompleted: Bool
}

struct MemoWidgetSnapshot: Codable, Equatable {
    var generatedAt: Date
    var reminders: [MemoWidgetReminderSnapshot]

    static let empty = MemoWidgetSnapshot(generatedAt: Date(), reminders: [])
}

enum MemoWidgetSnapshotStore {
    static let appGroupIdentifier = "group.com.example.MemoPing"

    private static let snapshotKey = "memoPing.widget.snapshot"

    static func load() -> MemoWidgetSnapshot {
        guard let data = defaults.data(forKey: snapshotKey) else {
            return .empty
        }

        return (try? JSONDecoder().decode(MemoWidgetSnapshot.self, from: data)) ?? .empty
    }

    static func save(_ snapshot: MemoWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: snapshotKey)
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}

enum MemoPingWidgetConstants {
    static let todayReminderKind = "MemoPingTodayRemindersWidget"
}
