import SwiftUI

struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel = CaptureViewModel()
    @State private var previewViewModel: PreviewViewModel?

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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                viewModel.stopRecording()
            }
        }
        .onDisappear {
            previewViewModel?.discardTemporaryImages()
            viewModel.cancelRecording()
        }
    }

    private var captureContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                GroupBox {
                    TextEditor(text: $viewModel.inputText)
                        .frame(minHeight: 150)
                        .padding(10)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                } label: {
                    Label("Text eingeben", systemImage: "keyboard")
                        .font(.headline)
                }

                GroupBox {
                    VStack(spacing: 14) {
                        Button {
                            viewModel.toggleRecording()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.isRecording ? Color.red : Color.accentColor)
                                        .frame(width: 58, height: 58)

                                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.speechButtonTitle)
                                        .font(.headline)

                                    Label(viewModel.speechStatusText, systemImage: viewModel.isRecording ? "waveform" : "mic")
                                        .font(.subheadline)
                                        .foregroundStyle(viewModel.isRecording ? .red : .secondary)
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
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
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
