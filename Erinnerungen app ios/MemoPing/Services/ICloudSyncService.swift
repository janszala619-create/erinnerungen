import CloudKit
import Foundation

enum ICloudAccountState: Equatable {
    case available
    case noAccount
    case restricted
    case couldNotDetermine
    case temporarilyUnavailable(String)

    var displayText: String {
        switch self {
        case .available:
            return "verfügbar"
        case .noAccount:
            return "nicht angemeldet"
        case .restricted:
            return "eingeschränkt"
        case .couldNotDetermine:
            return "unbekannt"
        case .temporarilyUnavailable:
            return "nicht verfügbar"
        }
    }

    var detailText: String {
        switch self {
        case .available:
            return "iCloud ist auf diesem Gerät verfügbar."
        case .noAccount:
            return "Melde dich in den iOS-Einstellungen bei iCloud an, um Memos zu synchronisieren."
        case .restricted:
            return "iCloud ist auf diesem Gerät eingeschränkt."
        case .couldNotDetermine:
            return "Der iCloud-Status konnte gerade nicht ermittelt werden."
        case .temporarilyUnavailable(let message):
            return message
        }
    }
}

final class ICloudSyncService {
    static let shared = ICloudSyncService()

    static var cloudKitContainerIdentifier: String {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.example.MemoPing"
        return "iCloud.\(bundleIdentifier)"
    }

    static var isCloudKitModelContainerEnabled: Bool {
        #if MEMOPING_UNSIGNED_IPA
        return false
        #else
        return true
        #endif
    }

    private init() {}

    func accountState() async -> ICloudAccountState {
        guard Self.isCloudKitModelContainerEnabled else {
            return .temporarilyUnavailable("Diese unsigned IPA nutzt lokalen Speicher. CloudKit wird erst in einem signierten Xcode-Build aktiviert.")
        }

        await withCheckedContinuation { continuation in
            CKContainer(identifier: Self.cloudKitContainerIdentifier).accountStatus { status, error in
                if let error {
                    #if DEBUG
                    print("MemoPing: iCloud Account Status Fehler: \(error)")
                    #endif
                    continuation.resume(returning: .temporarilyUnavailable(error.localizedDescription))
                    return
                }

                switch status {
                case .available:
                    continuation.resume(returning: .available)
                case .noAccount:
                    continuation.resume(returning: .noAccount)
                case .restricted:
                    continuation.resume(returning: .restricted)
                case .couldNotDetermine:
                    continuation.resume(returning: .couldNotDetermine)
                case .temporarilyUnavailable:
                    continuation.resume(returning: .temporarilyUnavailable("iCloud ist gerade nicht erreichbar. Die Synchronisation wird von iOS später erneut versucht."))
                @unknown default:
                    continuation.resume(returning: .couldNotDetermine)
                }
            }
        }
    }
}
