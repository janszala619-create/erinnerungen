import Combine
import Foundation
import SwiftData
import UIKit

enum PreviewValidationError: LocalizedError {
    case emptyDraft
    case pastReminderDate

    var errorDescription: String? {
        switch self {
        case .emptyDraft:
            return "Bitte erfasse Text oder füge ein Bild hinzu."
        case .pastReminderDate:
            return "Der Erinnerungstermin muss in der Zukunft liegen."
        }
    }
}

@MainActor
final class PreviewViewModel: ObservableObject {
    @Published var title: String
    @Published var bodyText: String
    @Published var recognizedText: String
    @Published var reminderDate: Date?
    @Published var hasReminder = false
    @Published var category: MemoCategory?
    @Published var priority: MemoPriority = .normal
    @Published var images: [UIImage]
    @Published var detectedInfo: DetectedInfo
    @Published var didSkipPhotoQuestion = false
    @Published var isProcessingImage = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private var sourceType: MemoSourceType
    private let ocrService = OCRService()
    private let dataDetectionService = DataDetectionService()
    private let imageStorage = ImageStorageService()
    private let notificationService = NotificationService()

    init(draft: MemoDraft) {
        title = draft.title
        bodyText = draft.bodyText
        recognizedText = draft.recognizedText
        images = draft.images
        detectedInfo = draft.detectedInfo
        sourceType = draft.sourceType
        reminderDate = draft.detectedInfo.dates.first { $0 > Date() }
    }

    var suggestedReminderDate: Date? {
        detectedInfo.dates.first { $0 > Date() }
    }

    var detectedDateStrings: [String] {
        detectedInfo.formattedDates()
    }

    var canSaveReminder: Bool {
        hasReminder && reminderDate != nil
    }

    func acceptSuggestedReminder() {
        reminderDate = suggestedReminderDate
        hasReminder = reminderDate != nil
    }

    func addImage(_ image: UIImage) async {
        images.append(image)
        sourceType = sourceType == .image ? .image : .mixed
        didSkipPhotoQuestion = false
        isProcessingImage = true

        do {
            let text = try await ocrService.recognizeText(in: image)
            appendRecognizedText(text)
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessingImage = false
    }

    func save(asReminder: Bool, modelContext: ModelContext) async throws {
        guard !bodyText.trimmed.isEmpty || !recognizedText.trimmed.isEmpty || !images.isEmpty else {
            throw PreviewValidationError.emptyDraft
        }

        isSaving = true
        defer { isSaving = false }

        let now = Date()
        let shouldScheduleReminder = asReminder && hasReminder

        if shouldScheduleReminder {
            guard let reminderDate, reminderDate > now else {
                throw PreviewValidationError.pastReminderDate
            }
        }

        var storedImageNames: [String] = []
        for image in images {
            storedImageNames.append(try imageStorage.save(image))
        }

        let finalTitle = generatedTitle()
        let detectedURLs = detectedInfo.urls.map(\.absoluteString)

        let memo = MemoItem(
            title: finalTitle,
            bodyText: bodyText.trimmed,
            recognizedText: recognizedText.trimmed,
            reminderDate: shouldScheduleReminder ? reminderDate : nil,
            hasReminder: shouldScheduleReminder,
            priority: priority,
            category: category,
            sourceType: sourceType,
            imageFileNames: storedImageNames,
            detectedPhoneNumbers: detectedInfo.phoneNumbers,
            detectedURLs: detectedURLs,
            detectedAddresses: detectedInfo.addresses,
            detectedDateStrings: detectedDateStrings
        )

        var didInsertMemo = false

        do {
            if shouldScheduleReminder {
                try await notificationService.scheduleNotification(for: memo)
            }

            modelContext.insert(memo)
            didInsertMemo = true
            try modelContext.save()
        } catch {
            if didInsertMemo {
                modelContext.delete(memo)
                try? modelContext.save()
            }

            if shouldScheduleReminder {
                notificationService.removeNotification(for: memo)
            }

            imageStorage.delete(fileNames: storedImageNames)
            throw error
        }
    }

    private func appendRecognizedText(_ text: String) {
        if recognizedText.trimmed.isEmpty {
            recognizedText = text
        } else {
            recognizedText += "\n\n" + text
        }

        var mergedInfo = detectedInfo
        mergedInfo.merge(dataDetectionService.detect(in: text))
        detectedInfo = mergedInfo

        if reminderDate == nil {
            reminderDate = suggestedReminderDate
        }
    }

    private func generatedTitle() -> String {
        let manualTitle = title.trimmed
        if !manualTitle.isEmpty {
            return manualTitle
        }

        let source = bodyText.trimmed.isEmpty ? recognizedText.trimmed : bodyText.trimmed
        if source.isEmpty {
            return images.isEmpty ? "Neue Notiz" : "Bildnotiz"
        }

        let words = source
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(6)
            .joined(separator: " ")

        return words.isEmpty ? "Neue Notiz" : words
    }
}
