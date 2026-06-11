import Foundation

struct DetectedInfo: Equatable {
    var dates: [Date] = []
    var phoneNumbers: [String] = []
    var urls: [URL] = []
    var addresses: [String] = []

    var isEmpty: Bool {
        dates.isEmpty && phoneNumbers.isEmpty && urls.isEmpty && addresses.isEmpty
    }

    mutating func merge(_ other: DetectedInfo) {
        for date in other.dates where !dates.contains(where: { abs($0.timeIntervalSince(date)) < 60 }) {
            dates.append(date)
        }

        phoneNumbers.appendUnique(contentsOf: other.phoneNumbers)
        urls.appendUnique(contentsOf: other.urls)
        addresses.appendUnique(contentsOf: other.addresses)
        dates.sort()
    }

    func formattedDates() -> [String] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return dates.map { formatter.string(from: $0) }
    }
}

private extension Array where Element: Equatable {
    mutating func appendUnique(contentsOf values: [Element]) {
        for value in values where !contains(value) {
            append(value)
        }
    }
}
