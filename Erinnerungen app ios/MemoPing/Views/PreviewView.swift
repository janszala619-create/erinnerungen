import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct PreviewView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel: PreviewViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var cameraSheet: CameraSheet?
    @State private var showDiscardConfirmation = false

    let onSave: () -> Void
    let onDiscard: () -> Void

    init(viewModel: PreviewViewModel, onSave: @escaping () -> Void, onDiscard: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
        self.onDiscard = onDiscard
    }

    var body: some View {
        Form {
            contentSection
            photoQuestionSection
            reminderSection
            organizationSection
            detectedInfoSection
            imagesSection
            saveSection
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await loadSelectedPhoto(newItem)
            }
        }
        .sheet(item: $cameraSheet) { _ in
            CameraPickerView { image in
                Task {
                    await viewModel.addImage(image)
                }
            }
        }
        .confirmationDialog("Entwurf verwerfen?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
            Button("Verwerfen", role: .destructive) {
                onDiscard()
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .alert("Hinweis", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var contentSection: some View {
        Section("Inhalt") {
            TextField("Titel", text: $viewModel.title)

            VStack(alignment: .leading, spacing: 8) {
                Text("Notiztext")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $viewModel.bodyText)
                    .frame(minHeight: 120)
            }

            if !viewModel.recognizedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Erkannter Text aus Bildern")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $viewModel.recognizedText)
                        .frame(minHeight: 110)
                }
            }
        }
    }

    private var photoQuestionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Möchtest du ein Foto hinzufügen?")
                    .font(.headline)

                HStack(spacing: 10) {
                    Button {
                        openCamera()
                    } label: {
                        Label("Foto aufnehmen", systemImage: "camera")
                    }
                    .buttonStyle(.bordered)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Aus Galerie wählen", systemImage: "photo")
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    viewModel.didSkipPhotoQuestion = true
                } label: {
                    Label("Überspringen", systemImage: "forward")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                if viewModel.didSkipPhotoQuestion {
                    Label("Kein Foto für diesen Eintrag", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if viewModel.isProcessingImage {
                    ProgressView("Bildtext wird erkannt")
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var reminderSection: some View {
        Section("Erinnerung") {
            if let suggestedDate = viewModel.suggestedReminderDate, !viewModel.hasReminder {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Soll daraus eine Erinnerung erstellt werden?")
                        .font(.headline)

                    Text(suggestedDate.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)

                    Button {
                        viewModel.acceptSuggestedReminder()
                    } label: {
                        Label("Datum übernehmen", systemImage: "bell.badge")
                    }
                }
                .padding(.vertical, 4)
            }

            Toggle("Als Erinnerung speichern", isOn: $viewModel.hasReminder)

            if viewModel.hasReminder {
                DatePicker(
                    "Datum und Uhrzeit",
                    selection: reminderDateBinding,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        }
    }

    private var organizationSection: some View {
        Section("Einordnung") {
            CategoryPickerView(selection: $viewModel.category)
            PriorityPickerView(selection: $viewModel.priority)
        }
    }

    @ViewBuilder
    private var detectedInfoSection: some View {
        if !viewModel.detectedInfo.isEmpty {
            Section("Erkannte Daten") {
                if !viewModel.detectedDateStrings.isEmpty {
                    detectedRows(title: "Datum", systemImage: "calendar", values: viewModel.detectedDateStrings)
                }

                if !viewModel.detectedInfo.phoneNumbers.isEmpty {
                    detectedRows(title: "Telefon", systemImage: "phone", values: viewModel.detectedInfo.phoneNumbers)
                }

                if !viewModel.detectedInfo.urls.isEmpty {
                    detectedRows(title: "Links", systemImage: "link", values: viewModel.detectedInfo.urls.map(\.absoluteString))
                }

                if !viewModel.detectedInfo.addresses.isEmpty {
                    detectedRows(title: "Adressen", systemImage: "mappin.and.ellipse", values: viewModel.detectedInfo.addresses)
                }
            }
        }
    }

    @ViewBuilder
    private var imagesSection: some View {
        if !viewModel.images.isEmpty {
            Section("Bilder") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(viewModel.images.enumerated()), id: \.offset) { _, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 112, height: 112)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                save(asReminder: false)
            } label: {
                Label("Als normale Notiz speichern", systemImage: "note.text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSaving)

            Button {
                save(asReminder: true)
            } label: {
                Label("Als Erinnerung speichern", systemImage: "bell")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.canSaveReminder || viewModel.isSaving)

            Button(role: .destructive) {
                showDiscardConfirmation = true
            } label: {
                Label("Verwerfen", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var reminderDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.reminderDate ?? Date().addingTimeInterval(3_600) },
            set: { viewModel.reminderDate = $0 }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private func detectedRows(title: String, systemImage: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))

            ForEach(values, id: \.self) { value in
                Text(value)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            viewModel.errorMessage = "Die Kamera ist auf diesem Gerät oder Simulator nicht verfügbar."
            return
        }

        cameraSheet = CameraSheet()
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await viewModel.addImage(image)
            } else {
                viewModel.errorMessage = "Das ausgewählte Bild konnte nicht geladen werden."
            }
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }

        selectedPhotoItem = nil
    }

    private func save(asReminder: Bool) {
        Task {
            do {
                try await viewModel.save(asReminder: asReminder, modelContext: modelContext)
                onSave()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}
