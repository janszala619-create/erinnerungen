import SwiftUI

enum MemoPriority: String, CaseIterable, Codable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low:
            return "Niedrig"
        case .normal:
            return "Normal"
        case .high:
            return "Hoch"
        }
    }

    var systemImage: String {
        switch self {
        case .low:
            return "arrow.down.circle"
        case .normal:
            return "minus.circle"
        case .high:
            return "exclamationmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .low:
            return .secondary
        case .normal:
            return .blue
        case .high:
            return .red
        }
    }
}
