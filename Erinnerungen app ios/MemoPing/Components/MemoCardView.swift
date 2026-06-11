import SwiftUI

struct MemoCardView: View {
    let item: MemoItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : iconName)
                    .foregroundStyle(item.isCompleted ? .green : item.priority.tint)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                        .strikethrough(item.isCompleted)
                        .lineLimit(2)

                    Text(item.previewText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                if !item.imageFileNames.isEmpty {
                    Image(systemName: "photo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Enthält Bild")
                }
            }

            HStack(spacing: 8) {
                if let category = item.category {
                    Label(category.displayName, systemImage: category.systemImage)
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .foregroundStyle(category.tint)
                }

                Label(item.priority.displayName, systemImage: item.priority.systemImage)
                    .labelStyle(.titleAndIcon)
                    .font(.caption)
                    .foregroundStyle(item.priority.tint)

                if item.hasReminder, let reminderDate = item.reminderDate {
                    Label(reminderDate.formatted(date: .abbreviated, time: .shortened), systemImage: "bell")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var iconName: String {
        if item.hasReminder {
            return "bell.circle"
        }
        if !item.imageFileNames.isEmpty {
            return "photo.circle"
        }
        return "note.text"
    }
}
