import Foundation
import SwiftUI
import SwiftData

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

@Model
final class MemoCategoryItem {
    var id: String = UUID().uuidString
    var name: String = ""
    var systemImage: String = "tag"
    var tintRawValue: String = "blue"
    var isDefault: Bool = false
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: String = UUID().uuidString,
        name: String,
        systemImage: String = "tag",
        tintRawValue: String = "blue",
        isDefault: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.systemImage = systemImage
        self.tintRawValue = tintRawValue
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension MemoCategoryItem {
    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Kategorie" : name
    }

    var tint: Color {
        Self.tint(for: tintRawValue)
    }

    static func tint(for rawValue: String) -> Color {
        switch rawValue {
        case "blue":
            return .blue
        case "green":
            return .green
        case "orange":
            return .orange
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "teal":
            return .teal
        case "indigo":
            return .indigo
        case "yellow":
            return .yellow
        case "red":
            return .red
        default:
            return .secondary
        }
    }

    static let availableSystemImages = [
        "tag",
        "briefcase",
        "person",
        "star",
        "doc.text",
        "lightbulb",
        "cart",
        "heart",
        "house",
        "phone",
        "calendar",
        "book"
    ]

    static let availableTintRawValues = [
        "blue",
        "green",
        "orange",
        "purple",
        "pink",
        "teal",
        "indigo",
        "yellow",
        "red",
        "gray"
    ]

    static func tintName(for rawValue: String) -> String {
        switch rawValue {
        case "blue":
            return "Blau"
        case "green":
            return "Grün"
        case "orange":
            return "Orange"
        case "purple":
            return "Lila"
        case "pink":
            return "Pink"
        case "teal":
            return "Türkis"
        case "indigo":
            return "Indigo"
        case "yellow":
            return "Gelb"
        case "red":
            return "Rot"
        default:
            return "Grau"
        }
    }

    static func item(for rawValue: String?, in categories: [MemoCategoryItem]) -> MemoCategoryItem? {
        guard let rawValue else {
            return nil
        }

        if let category = categories.first(where: { $0.id == rawValue }) {
            return category
        }

        guard let legacyCategory = MemoCategory(rawValue: rawValue) else {
            return nil
        }

        return MemoCategoryItem(
            id: legacyCategory.rawValue,
            name: legacyCategory.displayName,
            systemImage: legacyCategory.systemImage,
            tintRawValue: legacyCategory.defaultTintRawValue,
            isDefault: true
        )
    }

    static func seedDefaultsIfNeeded(in modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<MemoCategoryItem>()
        let existingCategories = try modelContext.fetch(descriptor)
        guard existingCategories.isEmpty else {
            return
        }

        for (index, category) in MemoCategory.allCases.enumerated() {
            modelContext.insert(
                MemoCategoryItem(
                    id: category.rawValue,
                    name: category.displayName,
                    systemImage: category.systemImage,
                    tintRawValue: category.defaultTintRawValue,
                    isDefault: true,
                    sortOrder: index
                )
            )
        }

        try modelContext.save()
    }
}

private extension MemoCategory {
    var defaultTintRawValue: String {
        switch self {
        case .uni:
            return "indigo"
        case .privat:
            return "green"
        case .wichtig:
            return "orange"
        case .dokumente:
            return "teal"
        case .ideen:
            return "yellow"
        }
    }
}
