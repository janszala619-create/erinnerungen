import SwiftUI

enum MemoCategory: String, CaseIterable, Codable, Identifiable {
    case uni
    case privat
    case wichtig
    case dokumente
    case ideen

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .uni:
            return "Uni"
        case .privat:
            return "Privat"
        case .wichtig:
            return "Wichtig"
        case .dokumente:
            return "Dokumente"
        case .ideen:
            return "Ideen"
        }
    }

    var systemImage: String {
        switch self {
        case .uni:
            return "graduationcap"
        case .privat:
            return "person"
        case .wichtig:
            return "star"
        case .dokumente:
            return "doc.text"
        case .ideen:
            return "lightbulb"
        }
    }

    var tint: Color {
        switch self {
        case .uni:
            return .indigo
        case .privat:
            return .green
        case .wichtig:
            return .orange
        case .dokumente:
            return .teal
        case .ideen:
            return .yellow
        }
    }
}
