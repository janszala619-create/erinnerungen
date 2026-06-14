import Foundation
import WidgetKit

enum MemoWidgetSnapshotUpdater {
    static func update(from items: [MemoItem]) {
        let calendar = Calendar.current
        let reminders = items
            .filter { item in
                guard item.hasReminder,
                      !item.isCompleted,
                      let reminderDate = item.reminderDate else {
                    return false
                }

                return calendar.isDateInToday(reminderDate)
            }
            .sorted { lhs, rhs in
                (lhs.reminderDate ?? .distantFuture) < (rhs.reminderDate ?? .distantFuture)
            }
            .map { item in
                MemoWidgetReminderSnapshot(
                    id: item.id.uuidString,
                    title: item.title.isEmpty ? "Ohne Titel" : item.title,
                    dueDate: item.reminderDate ?? Date(),
                    isCompleted: item.isCompleted
                )
            }

        MemoWidgetSnapshotStore.save(
            MemoWidgetSnapshot(generatedAt: Date(), reminders: reminders)
        )
        WidgetCenter.shared.reloadTimelines(ofKind: MemoPingWidgetConstants.todayReminderKind)
    }
}
