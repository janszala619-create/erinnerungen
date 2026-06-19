import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel = CaptureViewModel()
    @State private var previewViewModel: PreviewViewModel?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var cameraSheet: CameraSheet?

    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if let previewViewModel {
                    PreviewView(
                        viewModel: previewViewModel,
                        onSave: onComplete,
                        onDiscard: { dismiss() }
                    )
                } else {
                    captureContent
                }
            }
            .navigationTitle(previewViewModel == nil ? "Erfassen" : "Neue Erinnerung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.36), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if previewViewModel == nil {
                        Button("Abbrechen") {
                            viewModel.cancelRecording()
                            dismiss()
                        }
                    } else {
                        Button("Zurück") {
                            previewViewModel?.discardTemporaryImages()
                            previewViewModel = nil
                        }
                    }
                }
            }
        }
        .tint(RemindlyStyle.accent)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                viewModel.stopRecording()
            }
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                await loadSelectedPhotos(newItems)
            }
        }
        .sheet(item: $cameraSheet) { _ in
            CameraPickerView { image in
                Task {
                    await viewModel.addImage(image)
                }
            }
        }
        .onDisappear {
            previewViewModel?.discardTemporaryImages()
            viewModel.cancelRecording()
        }
    }

    private var captureContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                captureHero

                GroupBox {
                    TextEditor(text: $viewModel.inputText)
                        .frame(minHeight: 150)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .background(RemindlyStyle.elevatedFill, in: RoundedRectangle(cornerRadius: RemindlyStyle.controlRadius, style: .continuous))
                        .overlay {
                            if viewModel.inputText.isEmpty {
                                Text("Notiz oder Erinnerung eingeben")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .padding(.top, 18)
                                    .padding(.leading, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: RemindlyStyle.controlRadius, style: .continuous)
                                .strokeBorder(RemindlyStyle.border)
                        }
                } label: {
                    Label("Text eingeben", systemImage: "keyboard")
                        .font(.headline)
                }

                imageInputSection

                GroupBox {
                    VStack(spacing: 14) {
                        Button {
                            viewModel.toggleRecording()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.isRecording ? RemindlyStyle.danger : RemindlyStyle.accent)
                                        .frame(width: 58, height: 58)
                                        .shadow(color: (viewModel.isRecording ? RemindlyStyle.danger : RemindlyStyle.accent).opacity(0.28), radius: 18, y: 8)

                                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.speechButtonTitle)
                                        .font(.headline)

                                    Label(viewModel.speechStatusText, systemImage: viewModel.isRecording ? "waveform" : "mic")
                                        .font(.subheadline)
                                        .foregroundStyle(viewModel.isRecording ? RemindlyStyle.danger : RemindlyStyle.mutedText)
                                }

                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isPreparingSpeech)
                        .accessibilityLabel(viewModel.isRecording ? "Aufnahme stoppen" : "Sprache aufnehmen")

                        Text("Spracherkennung wird über iOS bereitgestellt. Deine gespeicherten Memos bleiben lokal auf dem Gerät.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } label: {
                    Label("Sprache aufnehmen", systemImage: "mic")
                        .font(.headline)
                }

                if let emptyTextHint = viewModel.emptyTextHint {
                    Label(emptyTextHint, systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    openPreview()
                } label: {
                    Label("Zur Vorschau", systemImage: "arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canContinue || viewModel.isProcessingImage)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 30)
        }
        .background(RemindlyStyle.backgroundGradient.ignoresSafeArea())
        .groupBoxStyle(RemindlyGroupBoxStyle())
        .onChange(of: viewModel.inputText) { _, _ in
            viewModel.textDidChange()
        }
        .alert("Hinweis", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var captureHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(RemindlyStyle.accentGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Schnell erfassen")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Text, Sprache oder Bild")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RemindlyStyle.mutedText)
                }
            }

            HStack(spacing: 10) {
                captureChip("Text", systemImage: "keyboard", isActive: !viewModel.inputText.trimmed.isEmpty)
                captureChip("Sprache", systemImage: "mic", isActive: viewModel.isRecording)
                captureChip("Bild", systemImage: "photo", isActive: !viewModel.imageAttachments.isEmpty)
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(RemindlyStyle.quietGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(RemindlyStyle.pink.opacity(0.10))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16))
        }
    }

    private func captureChip(_ title: String, systemImage: String, isActive: Bool) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(isActive ? Color.white : RemindlyStyle.mutedText)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(isActive ? RemindlyStyle.accent.opacity(0.28) : Color.black.opacity(0.16), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(isActive ? RemindlyStyle.accent.opacity(0.7) : Color.white.opacity(0.08))
            }
    }

    private var imageInputSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Button {
                        Task {
                            await openCamera()
                        }
                    } label: {
                        Label("Foto aufnehmen", systemImage: "camera")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canAddMoreImages)

                    if viewModel.canAddMoreImages {
                        PhotosPicker(
                            selection: $selectedPhotoItems,
                            maxSelectionCount: viewModel.remainingImageSlots,
                            matching: .images
                        ) {
                            Label("Aus Galerie wählen", systemImage: "photo")
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            viewModel.errorMessage = "Du kannst maximal 3 Bilder pro Memo hinzufügen."
                        } label: {
                            Label("Aus Galerie wählen", systemImage: "photo")
                        }
                        .buttonStyle(.bordered)
                        .disabled(true)
                    }
                }

                if let imageLimitMessage = viewModel.imageLimitMessage {
                    Label(imageLimitMessage, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if viewModel.imageAttachments.isEmpty {
                    Label("Du kannst auch direkt ein Foto oder einen Screenshot hinzufügen.", systemImage: "photo.on.rectangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.imageAttachments) { attachment in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: attachment.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 92, height: 92)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                    Button {
                                        viewModel.removeImage(attachment)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, .black.opacity(0.65))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(5)
                                    .accessibilityLabel("Bild entfernen")
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                if viewModel.isProcessingImage {
                    ProgressView("Bild wird erkannt...")
                        .font(.caption)
                }
            }
        } label: {
            Label("Bild hinzufügen", systemImage: "photo")
                .font(.headline)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private func openCamera() async {
        guard viewModel.canAddMoreImages else {
            viewModel.errorMessage = "Du kannst maximal 3 Bilder pro Memo hinzufügen."
            return
        }

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            viewModel.errorMessage = "Kamera ist auf diesem Gerät nicht verfügbar."
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                viewModel.errorMessage = "Die Kameraberechtigung wurde nicht erteilt."
                return
            }
        } else if status == .denied || status == .restricted {
            viewModel.errorMessage = "Die Kameraberechtigung wurde nicht erteilt."
            return
        }

        cameraSheet = CameraSheet()
    }

    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        guard viewModel.canAddMoreImages else {
            viewModel.errorMessage = "Du kannst maximal 3 Bilder pro Memo hinzufügen."
            selectedPhotoItems = []
            return
        }

        let itemsToLoad = Array(items.prefix(viewModel.remainingImageSlots))

        for item in itemsToLoad {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await viewModel.addImage(image)
                } else {
                    viewModel.errorMessage = "Das ausgewählte Bild konnte nicht geladen werden."
                }
            } catch {
                viewModel.errorMessage = "Das ausgewählte Bild konnte nicht geladen werden: \(error.localizedDescription)"
            }
        }

        if items.count > itemsToLoad.count {
            viewModel.errorMessage = "Es wurden nur die ersten \(itemsToLoad.count) Bilder übernommen. Maximal 3 Bilder pro Memo sind erlaubt."
        }

        selectedPhotoItems = []
    }

    private func openPreview() {
        guard viewModel.canContinue else {
            viewModel.errorMessage = "Bitte erfasse Text oder füge ein Bild hinzu."
            return
        }

        viewModel.stopRecording()
        previewViewModel = PreviewViewModel(draft: viewModel.makeDraft())
    }
}
