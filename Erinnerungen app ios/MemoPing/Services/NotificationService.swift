import Foundation
import UserNotifications

enum NotificationServiceError: LocalizedError {
    case permissionDenied
    case missingReminderDate
    case dateInPast
    case schedulingFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Benachrichtigungen sind nicht erlaubt. Du kannst sie in den Einstellungen aktivieren."
        case .missingReminderDate:
            return "Bitte wähle ein Datum und eine Uhrzeit für die Erinnerung."
        case .dateInPast:
            return "Der Erinnerungstermin muss in der Zukunft liegen."
        case .schedulingFailed(let message):
            return "Die Erinnerung konnte nicht geplant werden: \(message)"
        }
    }
}

final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func scheduleReminder(for memo: MemoItem) async throws {
        guard memo.hasReminder else {
            cancelReminder(for: memo)
            return
        }

        guard let reminderDate = memo.reminderDate else {
            throw NotificationServiceError.missingReminderDate
        }

        guard memo.reminderRepeatRule.isRepeating || reminderDate > Date() else {
            throw NotificationServiceError.dateInPast
        }

        guard try await ensureAuthorization() else {
            throw NotificationServiceError.permissionDenied
        }

        let content = UNMutableNotificationContent()
        content.title = memo.title.trimmed.isEmpty ? "MemoPing" : memo.title
        content.body = notificationBody(for: memo)
        content.sound = .default
        content.userInfo = ["memoID": memo.id.uuidString]

        let trigger = calendarTrigger(for: memo, reminderDate: reminderDate)
        guard trigger.nextTriggerDate() != nil else {
            throw NotificationServiceError.schedulingFailed("Für diese Wiederholung konnte kein nächster Termin ermittelt werden.")
        }

        let request = UNNotificationRequest(identifier: memo.id.uuidString, content: content, trigger: trigger)

        cancelReminder(for: memo)
        do {
            try await center.add(request)
        } catch {
            throw NotificationServiceError.schedulingFailed(error.localizedDescription)
        }
    }

    func cancelReminder(for memo: MemoItem) {
        cancelReminder(with: memo.id)
    }

    func cancelReminder(with id: UUID) {
        let identifier = id.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    #if DEBUG
    func scheduleDebugReminder() async throws {
        guard try await ensureAuthorization() else {
            throw NotificationServiceError.permissionDenied
        }

        let content = UNMutableNotificationContent()
        content.title = "MemoPing Test"
        content.body = "Diese Test-Erinnerung wurde lokal in 10 Sekunden geplant."
        content.sound = .default
        content.userInfo = ["debug": true]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(
            identifier: "debug-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }
    #endif

    static func statusText(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "Erlaubt"
        case .denied:
            return "Nicht erlaubt"
        case .notDetermined:
            return "Noch nicht gefragt"
        case .provisional, .ephemeral:
            return "Eingeschränkt / unbekannt"
        @unknown default:
            return "Eingeschränkt / unbekannt"
        }
    }

    private func ensureAuthorization() async throws -> Bool {
        let status = await getAuthorizationStatus()

        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return try await requestAuthorization()
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func notificationBody(for memo: MemoItem) -> String {
        let text = memo.previewText.trimmed.isEmpty ? "Erinnerung aus MemoPing" : memo.previewText.trimmed

        guard text.count > 120 else {
            return text
        }

        let endIndex = text.index(text.startIndex, offsetBy: 120)
        return String(text[..<endIndex]) + "..."
    }

    private func calendarTrigger(for memo: MemoItem, reminderDate: Date) -> UNCalendarNotificationTrigger {
        let calendar = Calendar.current
        let components: DateComponents

        switch memo.reminderRepeatRule {
        case .none:
            components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        case .daily:
            components = calendar.dateComponents([.hour, .minute], from: reminderDate)
        case .weekly:
            components = calendar.dateComponents([.weekday, .hour, .minute], from: reminderDate)
        case .monthly:
            components = calendar.dateComponents([.day, .hour, .minute], from: reminderDate)
        case .yearly:
            components = calendar.dateComponents([.month, .day, .hour, .minute], from: reminderDate)
        }

        return UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: memo.reminderRepeatRule.isRepeating
        )
    }
}
