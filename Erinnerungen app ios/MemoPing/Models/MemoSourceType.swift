enum MemoSourceType: String, Codable {
    case text
    case voice
    case image
    case mixed

    var displayName: String {
        switch self {
        case .text:
            return "Text"
        case .voice:
            return "Sprache"
        case .image:
            return "Bild"
        case .mixed:
            return "Gemischt"
        }
    }
}
