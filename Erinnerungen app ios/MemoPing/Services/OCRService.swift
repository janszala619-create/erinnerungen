import CoreImage
import ImageIO
import UIKit
import Vision

enum OCRServiceError: LocalizedError {
    case invalidImage
    case noTextFound
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Das Bild konnte nicht gelesen werden."
        case .noTextFound:
            return "In diesem Bild wurde kein Text erkannt."
        case .recognitionFailed(let message):
            return "Die Texterkennung ist fehlgeschlagen: \(message)"
        }
    }
}

final class OCRService {
    static let shared = OCRService()

    private init() {}

    func recognizeText(in image: UIImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try Self.performRecognition(in: image, languages: ["de-DE", "en-US"]))
                } catch OCRServiceError.noTextFound {
                    continuation.resume(throwing: OCRServiceError.noTextFound)
                } catch {
                    do {
                        continuation.resume(returning: try Self.performRecognition(in: image, languages: []))
                    } catch OCRServiceError.noTextFound {
                        continuation.resume(throwing: OCRServiceError.noTextFound)
                    } catch OCRServiceError.invalidImage {
                        continuation.resume(throwing: OCRServiceError.invalidImage)
                    } catch {
                        continuation.resume(throwing: OCRServiceError.recognitionFailed(error.localizedDescription))
                    }
                }
            }
        }
    }

    private static func performRecognition(in image: UIImage, languages: [String]) throws -> String {
        let preparedImage = image.preparedForOCR(maxDimension: 2_600)

        guard let cgImage = preparedImage.ocrCGImage else {
            throw OCRServiceError.invalidImage
        }

        var requestError: Error?
        var observations: [VNRecognizedTextObservation] = []

        let request = VNRecognizeTextRequest { request, error in
            requestError = error
            observations = request.results as? [VNRecognizedTextObservation] ?? []
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        if !languages.isEmpty {
            request.recognitionLanguages = languages
        }

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: CGImagePropertyOrientation(preparedImage.imageOrientation),
            options: [:]
        )

        try handler.perform([request])

        if let requestError {
            throw requestError
        }

        let lines = observations
            .sortedForReadingOrder()
            .compactMap { $0.topCandidates(1).first?.string.cleanedOCRLine }
            .filter { !$0.isEmpty }

        let text = lines.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw OCRServiceError.noTextFound
        }

        return text
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}

private extension UIImage {
    var ocrCGImage: CGImage? {
        if let cgImage {
            return cgImage
        }

        guard let ciImage else {
            return nil
        }

        return CIContext().createCGImage(ciImage, from: ciImage.extent)
    }

    func preparedForOCR(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension, longestSide > 0 else {
            return self
        }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

private extension String {
    var cleanedOCRLine: String {
        components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private extension Array where Element == VNRecognizedTextObservation {
    func sortedForReadingOrder() -> [VNRecognizedTextObservation] {
        sorted { lhs, rhs in
            let yDistance = abs(lhs.boundingBox.midY - rhs.boundingBox.midY)
            if yDistance > 0.02 {
                return lhs.boundingBox.midY > rhs.boundingBox.midY
            }

            return lhs.boundingBox.minX < rhs.boundingBox.minX
        }
    }
}
