import SwiftUI
import WidgetKit

struct MemoPingTodayReminderEntry: TimelineEntry {
    let date: Date
    let snapshot: MemoWidgetSnapshot
}

struct MemoPingTodayReminderProvider: TimelineProvider {
    func placeholder(in context: Context) -> MemoPingTodayReminderEntry {
        MemoPingTodayReminderEntry(
            date: Date(),
            snapshot: MemoWidgetSnapshot(
                generatedAt: Date(),
                reminders: [
                    MemoWidgetReminderSnapshot(
                        id: UUID().uuidString,
                        title: "Arzttermin",
                        dueDate: Date().addingTimeInterval(3_600),
                        isCompleted: false
                    )
                ]
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MemoPingTodayReminderEntry) -> Void) {
        completion(MemoPingTodayReminderEntry(date: Date(), snapshot: MemoWidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoPingTodayReminderEntry>) -> Void) {
        let entry = MemoPingTodayReminderEntry(date: Date(), snapshot: MemoWidgetSnapshotStore.load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct MemoPingTodayReminderWidgetView: View {
    let entry: MemoPingTodayReminderEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Heute", systemImage: "bell")
                    .font(.headline)
                Spacer()
                Text(entry.snapshot.generatedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if entry.snapshot.reminders.isEmpty {
                Spacer()
                Text("Keine offenen Erinnerungen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.snapshot.reminders.prefix(4)) { reminder in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(reminder.dueDate.formatted(date: .omitted, time: .shortened))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 44, alignment: .leading)

                            Text(reminder.title)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

struct MemoPingTodayRemindersWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: MemoPingWidgetConstants.todayReminderKind,
            provider: MemoPingTodayReminderProvider()
        ) { entry in
            MemoPingTodayReminderWidgetView(entry: entry)
        }
        .configurationDisplayName("MemoPing Erinnerungen")
        .description("Zeigt deine offenen Erinnerungen für heute.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
