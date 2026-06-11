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
    @Published var isPreparingSpeech = false
    @Published var hasAttemptedSpeechInput = false
    @Published var isProcessingImage = false
    @Published var errorMessage: String?
    @Published var sourceType: MemoSourceType = .text

    private let speechService = SpeechRecognitionService()
    private let ocrService = OCRService.shared
    private let dataDetectionService = DataDetectionService.shared
    private var cancellables: Set<AnyCancellable> = []

    init() {
        speechService.$transcript
            .receive(on: RunLoop.main)
            .sink { [weak self] transcript in
                guard let self, !transcript.trimmed.isEmpty else { return }
                self.inputText = transcript
                self.sourceType = .voice
                self.recalculateDetectedInfo()
            }
            .store(in: &cancellables)

        speechService.$isRecording
            .receive(on: RunLoop.main)
            .assign(to: &$isRecording)

        speechService.$errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                guard let message else { return }
                self?.errorMessage = message
            }
            .store(in: &cancellables)
    }

    var canContinue: Bool {
        !inputText.trimmed.isEmpty || !recognizedText.trimmed.isEmpty || !images.isEmpty
    }

    var speechStatusText: String {
        if isPreparingSpeech {
            return "Transkription wird erstellt..."
        }

        if isRecording {
            return "Aufnahme läuft..."
        }

        if !inputText.trimmed.isEmpty {
            return "Transkription verfügbar"
        }

        if hasAttemptedSpeechInput && inputText.trimmed.isEmpty {
            return "Keine Sprache erkannt"
        }

        return "Bereit"
    }

    var speechButtonTitle: String {
        isRecording ? "Aufnahme stoppen" : "Aufnahme starten"
    }

    var emptyTextHint: String? {
        canContinue ? nil : "Sprich etwas ein oder gib Text ein."
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
        hasAttemptedSpeechInput = true
        speechService.stopRecording()
        isRecording = false
        isPreparingSpeech = false
        recalculateDetectedInfo()
    }

    func cancelRecording() {
        speechService.cancelRecording()
        isRecording = false
        isPreparingSpeech = false
    }

    func textDidChange() {
        if !inputText.trimmed.isEmpty {
            sourceType = sourceType == .image ? .mixed : sourceType
        }
        recalculateDetectedInfo()
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
        let info = dataDetectionService.detect(in: [inputText, recognizedText].joined(separator: "\n"))

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
        guard !isRecording, !isPreparingSpeech else {
            return
        }

        hasAttemptedSpeechInput = true
        isPreparingSpeech = true
        await speechService.startRecording()
        isPreparingSpeech = false
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
