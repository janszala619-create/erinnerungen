import Combine
import Foundation

enum MemoListSection: String, CaseIterable, Identifiable {
    case today
    case upcoming
    case noReminder
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return "Heute"
        case .upcoming:
            return "Kommend"
        case .noReminder:
            return "Ohne Erinnerung"
        case .completed:
            return "Erledigt"
        }
    }
}

struct MemoSectionGroup: Identifiable {
    let section: MemoListSection
    let items: [MemoItem]

    var id: MemoListSection { section }
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategory: MemoCategory?

    func sectionGroups(from items: [MemoItem]) -> [MemoSectionGroup] {
        let filteredItems = filtered(items)
        let calendar = Calendar.current

        let today = filteredItems.filter { item in
            guard !item.isCompleted, item.hasReminder, let reminderDate = item.reminderDate else {
                return false
            }
            return calendar.isDateInToday(reminderDate)
        }

        let upcoming = filteredItems.filter { item in
            guard !item.isCompleted, item.hasReminder, let reminderDate = item.reminderDate else {
                return false
            }
            return !calendar.isDateInToday(reminderDate)
        }

        let noReminder = filteredItems.filter { item in
            !item.isCompleted && !item.hasReminder
        }

        let completed = filteredItems.filter(\.isCompleted)

        return [
            MemoSectionGroup(section: .today, items: sorted(today)),
            MemoSectionGroup(section: .upcoming, items: sorted(upcoming)),
            MemoSectionGroup(section: .noReminder, items: sorted(noReminder)),
            MemoSectionGroup(section: .completed, items: sorted(completed))
        ].filter { !$0.items.isEmpty }
    }

    private func filtered(_ items: [MemoItem]) -> [MemoItem] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return items.filter { item in
            let categoryMatches = selectedCategory == nil || item.category == selectedCategory

            guard categoryMatches else {
                return false
            }

            guard !normalizedSearch.isEmpty else {
                return true
            }

            let searchableText = [
                item.title,
                item.bodyText,
                item.recognizedText,
                item.category?.displayName ?? "",
                item.priority.displayName,
                item.detectedPhoneNumbers.joined(separator: " "),
                item.detectedURLs.joined(separator: " "),
                item.detectedAddresses.joined(separator: " "),
                item.detectedDateStrings.joined(separator: " ")
            ].joined(separator: " ").lowercased()

            return searchableText.contains(normalizedSearch)
        }
    }

    private func sorted(_ items: [MemoItem]) -> [MemoItem] {
        items.sorted { lhs, rhs in
            switch (lhs.reminderDate, rhs.reminderDate) {
            case let (lhsDate?, rhsDate?):
                return lhsDate < rhsDate
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.createdAt > rhs.createdAt
            }
        }
    }
}
