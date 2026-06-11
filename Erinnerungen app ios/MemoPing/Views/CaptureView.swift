import PhotosUI
import SwiftUI
import UIKit

struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = CaptureViewModel()
    @State private var previewViewModel: PreviewViewModel?
    @State private var selectedPhotoItem: PhotosPickerItem?
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
            .navigationTitle(previewViewModel == nil ? "Erfassen" : "Vorschau")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if previewViewModel == nil {
                        Button("Schließen") {
                            dismiss()
                        }
                    } else {
                        Button("Zurück") {
                            previewViewModel = nil
                        }
                    }
                }
            }
        }
        .sheet(item: $cameraSheet) { _ in
            CameraPickerView { image in
                Task {
                    await viewModel.addImage(image)
                }
            }
        }
    }

    private var captureContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Button {
                    viewModel.toggleRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.isRecording ? Color.red : Color.blue)
                            .frame(width: 108, height: 108)

                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.isRecording ? "Aufnahme stoppen" : "Sprache aufnehmen")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Text")
                        .font(.headline)

                    TextEditor(text: $viewModel.inputText)
                        .frame(minHeight: 150)
                        .padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
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
                }

                imageActions

                if viewModel.isProcessingImage {
                    Label("Bildtext wird erkannt", systemImage: "text.viewfinder")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !viewModel.recognizedText.isEmpty {
                    recognizedTextBox
                }

                if !viewModel.images.isEmpty {
                    imageStrip(images: viewModel.images)
                }

                Button {
                    openPreview()
                } label: {
                    Label("Weiter zur Vorschau", systemImage: "arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canContinue || viewModel.isProcessingImage)
            }
            .padding()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await loadSelectedPhoto(newItem)
            }
        }
        .alert("Hinweis", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var imageActions: some View {
        HStack(spacing: 12) {
            Button {
                openCamera()
            } label: {
                Label("Foto aufnehmen", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("Bild auswählen", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var recognizedTextBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Erkannter Bildtext", systemImage: "text.viewfinder")
                .font(.headline)

            Text(viewModel.recognizedText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private func imageStrip(images: [UIImage]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
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

    private func openPreview() {
        guard viewModel.canContinue else {
            viewModel.errorMessage = "Bitte erfasse Text oder füge ein Bild hinzu."
            return
        }

        viewModel.stopRecording()
        previewViewModel = PreviewViewModel(draft: viewModel.makeDraft())
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
}
