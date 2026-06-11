import Combine
import Foundation
import UserNotifications

enum NotificationServiceError: LocalizedError {
    case permissionDenied
    case missingReminderDate
    case dateInPast

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Benachrichtigungen sind nicht erlaubt. Du kannst sie in den Einstellungen aktivieren."
        case .missingReminderDate:
            return "Bitte wähle ein Datum und eine Uhrzeit für die Erinnerung."
        case .dateInPast:
            return "Der Erinnerungstermin muss in der Zukunft liegen."
        }
    }
}

@MainActor
final class NotificationService: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        await refreshAuthorizationStatus()
        return granted
    }

    func scheduleNotification(for memo: MemoItem) async throws {
        guard memo.hasReminder else {
            removeNotification(for: memo)
            return
        }

        guard let reminderDate = memo.reminderDate else {
            throw NotificationServiceError.missingReminderDate
        }

        guard reminderDate > Date() else {
            throw NotificationServiceError.dateInPast
        }

        if try await ensureAuthorization() == false {
            throw NotificationServiceError.permissionDenied
        }

        let content = UNMutableNotificationContent()
        content.title = memo.title
        content.body = memo.previewText
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: memo.notificationIdentifier, content: content, trigger: trigger)

        removeNotification(for: memo)
        try await center.add(request)
    }

    func removeNotification(for memo: MemoItem) {
        center.removePendingNotificationRequests(withIdentifiers: [memo.notificationIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [memo.notificationIdentifier])
    }

    var statusText: String {
        switch authorizationStatus {
        case .authorized:
            return "Erlaubt"
        case .denied:
            return "Abgelehnt"
        case .notDetermined:
            return "Noch nicht gefragt"
        case .provisional:
            return "Vorläufig erlaubt"
        case .ephemeral:
            return "Temporär erlaubt"
        @unknown default:
            return "Unbekannt"
        }
    }

    private func ensureAuthorization() async throws -> Bool {
        await refreshAuthorizationStatus()

        switch authorizationStatus {
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
}
