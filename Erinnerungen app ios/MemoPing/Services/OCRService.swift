import ImageIO
import UIKit
import Vision

enum OCRServiceError: LocalizedError {
    case invalidImage
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Das Bild konnte nicht gelesen werden."
        case .noTextFound:
            return "In diesem Bild wurde kein Text erkannt."
        }
    }
}

final class OCRService {
    func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest { request, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    let observations = request.results as? [VNRecognizedTextObservation] ?? []
                    let recognizedLines = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }

                    let text = recognizedLines.joined(separator: "\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if text.isEmpty {
                        continuation.resume(throwing: OCRServiceError.noTextFound)
                    } else {
                        continuation.resume(returning: text)
                    }
                }

                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["de-DE", "en-US"]

                let handler = VNImageRequestHandler(
                    cgImage: cgImage,
                    orientation: CGImagePropertyOrientation(image.imageOrientation),
                    options: [:]
                )

                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
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
