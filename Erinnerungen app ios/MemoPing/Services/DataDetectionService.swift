import Foundation

final class DataDetectionService {
    private let detector: NSDataDetector?

    init() {
        let checkingTypes: NSTextCheckingResult.CheckingType = [.date, .phoneNumber, .link, .address]
        detector = try? NSDataDetector(types: checkingTypes.rawValue)
    }

    func detect(in text: String) -> DetectedInfo {
        guard let detector, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return DetectedInfo()
        }

        var detectedInfo = DetectedInfo()
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = detector.matches(in: text, options: [], range: range)

        for match in matches {
            if match.resultType.contains(.date), let date = match.date {
                detectedInfo.dates.append(date)
            }

            if match.resultType.contains(.phoneNumber), let phoneNumber = match.phoneNumber {
                detectedInfo.phoneNumbers.append(phoneNumber)
            }

            if match.resultType.contains(.link), let url = match.url {
                detectedInfo.urls.append(url)
            }

            if match.resultType.contains(.address) {
                detectedInfo.addresses.append(addressString(from: match, in: text))
            }
        }

        return detectedInfo.uniqued()
    }

    private func addressString(from match: NSTextCheckingResult, in text: String) -> String {
        if let components = match.addressComponents {
            let values = [
                components[.street],
                components[.city],
                components[.state],
                components[.zip],
                components[.country]
            ].compactMap { $0 }

            if !values.isEmpty {
                return values.joined(separator: ", ")
            }
        }

        guard let range = Range(match.range, in: text) else {
            return "Erkannte Adresse"
        }

        return String(text[range])
    }
}

private extension DetectedInfo {
    func uniqued() -> DetectedInfo {
        var info = DetectedInfo()
        info.merge(self)
        return info
    }
}
