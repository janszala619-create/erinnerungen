import Combine
import Foundation
import UIKit

@MainActor
final class CaptureViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var recognizedText = ""
    @Published var detectedInfo = DetectedInfo()
    @Published var images: [UIImage] = []
    @Published var isRecording = false
    @Published var isProcessingImage = false
    @Published var errorMessage: String?
    @Published var sourceType: MemoSourceType = .text

    private let speechService = SpeechRecognitionService()
    private let ocrService = OCRService()
    private let dataDetectionService = DataDetectionService()

    var canContinue: Bool {
        !inputText.trimmed.isEmpty || !recognizedText.trimmed.isEmpty || !images.isEmpty
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            Task {
                await startRecording()
            }
        }
    }

    func stopRecording() {
        speechService.stopTranscribing()
        isRecording = false
    }

    func addImage(_ image: UIImage) async {
        images.append(image)
        sourceType = sourceType == .text && inputText.trimmed.isEmpty ? .image : .mixed
        isProcessingImage = true

        do {
            let text = try await ocrService.recognizeText(in: image)
            appendRecognizedText(text)
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessingImage = false
    }

    func makeDraft() -> MemoDraft {
        var info = detectedInfo
        info.merge(dataDetectionService.detect(in: [inputText, recognizedText].joined(separator: "\n")))

        return MemoDraft(
            title: "",
            bodyText: inputText.trimmed,
            recognizedText: recognizedText.trimmed,
            images: images,
            sourceType: sourceType,
            detectedInfo: info
        )
    }

    private func startRecording() async {
        do {
            try await speechService.requestPermissions()
            try speechService.startTranscribing { [weak self] transcript in
                guard let self else { return }
                self.inputText = transcript
                self.sourceType = .voice
                self.recalculateDetectedInfo()
            } onError: { [weak self] message in
                self?.errorMessage = message
                self?.isRecording = false
            }
            isRecording = true
        } catch {
            errorMessage = error.localizedDescription
            isRecording = false
        }
    }

    private func appendRecognizedText(_ text: String) {
        if recognizedText.trimmed.isEmpty {
            recognizedText = text
        } else {
            recognizedText += "\n\n" + text
        }
        recalculateDetectedInfo()
    }

    private func recalculateDetectedInfo() {
        detectedInfo = dataDetectionService.detect(in: [inputText, recognizedText].joined(separator: "\n"))
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
