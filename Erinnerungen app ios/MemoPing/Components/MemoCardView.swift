import SwiftUI

struct MemoCardView: View {
    let item: MemoItem
    var category: MemoCategoryItem? = nil
    var onToggleCompleted: (() -> Void)?
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 8) {
                Button {
                    onToggleCompleted?()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(item.isCompleted ? RemindlyStyle.success : cardTint, lineWidth: 3)
                            .frame(width: 34, height: 34)

                        if item.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.black))
                                .foregroundStyle(RemindlyStyle.success)
                        }
                    }
                }
                .buttonStyle(.borderless)
                .disabled(onToggleCompleted == nil)
                .accessibilityLabel(item.isCompleted ? "Als offen markieren" : "Als erledigt markieren")

                if item.hasReminder {
                    Image(systemName: "bell.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(cardTint)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let category {
                        Label(category.displayName, systemImage: category.systemImage)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(category.tint)
                            .lineLimit(1)
                    } else {
                        Label(item.hasReminder ? "Erinnerung" : "Notiz", systemImage: item.hasReminder ? "bell" : "doc.text")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(cardTint)
                    }

                    Spacer(minLength: 6)

                    if item.priority != .normal {
                        Label(item.priority.displayName, systemImage: item.priority.systemImage)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(item.priority.tint)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color.white.opacity(item.isCompleted ? 0.45 : 1.0))
                        .strikethrough(item.isCompleted)
                        .lineLimit(2)

                    Text(item.previewText)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(3)
                }

                metadataRow
            }

            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RemindlyStyle.danger)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Memo löschen")
            }
        }
        .padding(16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: RemindlyStyle.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RemindlyStyle.cardRadius, style: .continuous)
                .strokeBorder(cardTint.opacity(0.30), lineWidth: 1)
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(cardTint)
                .frame(width: 4)
                .padding(.vertical, 18)
        }
        .opacity(item.isCompleted ? 0.72 : 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var cardTint: Color {
        if let category {
            return category.tint
        }

        if item.priority != .normal {
            return item.priority.tint
        }

        if item.hasReminder {
            return RemindlyStyle.accent
        }

        return RemindlyStyle.pink
    }

    private var cardBackground: LinearGradient {
        RemindlyStyle.tintedCardGradient(cardTint)
    }

    private var metadataRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if item.hasReminder, let reminderDate = item.reminderDate {
                    memoBadge(reminderDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar", tint: RemindlyStyle.cyan)

                    if item.reminderRepeatRule.isRepeating {
                        memoBadge(item.reminderRepeatRule.displayName, systemImage: item.reminderRepeatRule.systemImage, tint: .secondary)
                    }

                    if item.reminderLeadTime.hasLeadNotification {
                        memoBadge(item.reminderLeadTime.shortDisplayName, systemImage: item.reminderLeadTime.systemImage, tint: .secondary)
                    }
                }

                if !item.detectedPhoneNumbers.isEmpty {
                    memoBadge("Telefon", systemImage: "phone", tint: RemindlyStyle.mutedText)
                }

                if !item.detectedURLs.isEmpty {
                    memoBadge("Link", systemImage: "link", tint: RemindlyStyle.mutedText)
                }

                if !item.detectedDateStrings.isEmpty {
                    memoBadge("Datum", systemImage: "calendar.badge.clock", tint: RemindlyStyle.mutedText)
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
            .background(tint.opacity(0.14), in: Capsule())
    }
}
