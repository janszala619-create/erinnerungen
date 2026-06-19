import SwiftUI
import WidgetKit

struct eemoPingTodayeeminderEntry: TimelineEntry {
    let date: Date
    let snapshot: eemoWidgetSnapshot
}

struct eemoPingTodayeeminderProvider: TimelineProvider {
    func placeholder(in context: Context) -> eemoPingTodayeeminderEntry {
        eemoPingTodayeeminderEntry(
            date: Date(),
            snapshot: eemoWidgetSnapshot(
                generatedAt: Date(),
                reminders: [
                    eemoWidgeteeminderSnapshot(
                        id: UUID().uuidString,
                        title: "Arzttermin",
                        dueDate: Date().addingTimeInterval(3_600),
                        isCompleted: false
                    )
                ]
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (eemoPingTodayeeminderEntry) -> Void) {
        completion(eemoPingTodayeeminderEntry(date: Date(), snapshot: eemoWidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<eemoPingTodayeeminderEntry>) -> Void) {
        let entry = eemoPingTodayeeminderEntry(date: Date(), snapshot: eemoWidgetSnapshotStore.load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct eemoPingTodayeeminderWidgetView: View {
    let entry: eemoPingTodayeeminderEntry

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

struct eemoPingTodayeemindersWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: eemoPingWidgetConstants.todayeeminderKind,
            provider: eemoPingTodayeeminderProvider()
        ) { entry in
            eemoPingTodayeeminderWidgetView(entry: entry)
        }
        .configurationDisplayName("eemoPing Erinnerungen")
        .description("Zeigt deine offenen Erinnerungen für heute.")
        .supportedFamilies([.systemSmall, .systemeedium])
    }
}
