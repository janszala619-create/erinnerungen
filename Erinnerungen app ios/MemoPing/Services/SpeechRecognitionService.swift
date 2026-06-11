import AVFoundation
import Speech

enum SpeechRecognitionServiceError: LocalizedError {
    case recognizerUnavailable
    case onDeviceRecognitionUnavailable
    case speechPermissionDenied
    case microphonePermissionDenied

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Die Spracherkennung ist gerade nicht verfügbar."
        case .onDeviceRecognitionUnavailable:
            return "Die lokale Spracherkennung ist auf diesem Gerät oder Simulator nicht verfügbar."
        case .speechPermissionDenied:
            return "Die Berechtigung für Spracherkennung fehlt."
        case .microphonePermissionDenied:
            return "Die Mikrofonberechtigung fehlt."
        }
    }
}

final class SpeechRecognitionService {
    private let recognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    init(locale: Locale = Locale(identifier: "de-DE")) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestPermissions() async throws {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            throw SpeechRecognitionServiceError.speechPermissionDenied
        }

        let microphoneGranted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        guard microphoneGranted else {
            throw SpeechRecognitionServiceError.microphonePermissionDenied
        }
    }

    func startTranscribing(
        onResult: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) throws {
        guard let recognizer, recognizer.isAvailable else {
            throw SpeechRecognitionServiceError.recognizerUnavailable
        }

        guard recognizer.supportsOnDeviceRecognition else {
            throw SpeechRecognitionServiceError.onDeviceRecognitionUnavailable
        }

        stopTranscribing()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        recognitionRequest = request

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                DispatchQueue.main.async {
                    onResult(result.bestTranscription.formattedString)
                }
            }

            if let error {
                DispatchQueue.main.async {
                    onError(error.localizedDescription)
                }
                self?.stopTranscribing()
                return
            }

            if result?.isFinal == true {
                self?.stopTranscribing()
            }
        }
    }

    func stopTranscribing() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
