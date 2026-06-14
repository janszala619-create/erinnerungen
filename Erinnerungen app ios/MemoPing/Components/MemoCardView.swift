import SwiftUI

struct MemoCardView: View {
    let item: MemoItem
    var onToggleCompleted: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : iconName)
                    .foregroundStyle(item.isCompleted ? .green : item.priority.tint)
                    .font(.title3.weight(.semibold))
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                        .strikethrough(item.isCompleted)
                        .lineLimit(2)

                    Text(item.previewText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 8)

                HStack(spacing: 10) {
                    if !item.imageFileNames.isEmpty {
                        Image(systemName: "photo")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Enthält Bild")
                    }

                    if let onToggleCompleted {
                        Button {
                            onToggleCompleted()
                        } label: {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(item.isCompleted ? .green : .secondary)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(item.isCompleted ? "Als offen markieren" : "Als erledigt markieren")
                    }
                }
            }

            metadataRow
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05))
        }
        .opacity(item.isCompleted ? 0.72 : 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
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

    private var metadataRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let category = item.category {
                    memoBadge(category.displayName, systemImage: category.systemImage, tint: category.tint)
                }

                memoBadge(item.priority.displayName, systemImage: item.priority.systemImage, tint: item.priority.tint)

                if item.hasReminder, let reminderDate = item.reminderDate {
                    memoBadge(reminderDate.formatted(date: .abbreviated, time: .shortened), systemImage: "bell", tint: .secondary)

                    if item.reminderRepeatRule.isRepeating {
                        memoBadge(item.reminderRepeatRule.displayName, systemImage: item.reminderRepeatRule.systemImage, tint: .secondary)
                    }
                }

                if !item.detectedPhoneNumbers.isEmpty {
                    iconBadge("phone", label: "Telefonnummer erkannt")
                }

                if !item.detectedURLs.isEmpty {
                    iconBadge("link", label: "Link erkannt")
                }

                if !item.detectedDateStrings.isEmpty {
                    iconBadge("calendar", label: "Datum erkannt")
                }
            }
            .padding(.vertical, 1)
        }
        .accessibilityLabel("Details zur Erinnerung")
    }

    private func memoBadge(_ title: String, systemImage: String, tint: Color) -> some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12), in: Capsule())
    }

    private func iconBadge(_ systemImage: String, label: String) -> some View {
        Image(systemName: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: 26, height: 26)
            .background(Color(.tertiarySystemGroupedBackground), in: Circle())
            .accessibilityLabel(label)
    }
}
