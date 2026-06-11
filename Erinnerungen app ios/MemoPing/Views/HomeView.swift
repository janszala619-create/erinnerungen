import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemoItem.createdAt, order: .reverse) private var items: [MemoItem]

    @StateObject private var viewModel = HomeViewModel()
    @State private var isCapturePresented = false
    @State private var errorMessage: String?

    private let imageStorage = ImageStorageService()

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 92)
                }

            CaptureButton {
                isCapturePresented = true
            }
            .padding(.bottom, 22)
        }
        .navigationTitle("MemoPing")
        .searchable(text: $viewModel.searchText, prompt: "Suchen")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                categoryFilterMenu
            }
        }
        .sheet(isPresented: $isCapturePresented) {
            CaptureView {
                isCapturePresented = false
            }
        }
        .alert("Hinweis", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        let groups = viewModel.sectionGroups(from: items)

        if groups.isEmpty {
            ContentUnavailableView(
                "Noch keine Einträge",
                systemImage: "tray",
                description: Text("Tippe auf den Plus-Button, um eine Notiz, Erinnerung oder Bildnotiz zu erfassen.")
            )
        } else {
            List {
                ForEach(groups) { group in
                    Section(group.section.title) {
                        ForEach(group.items) { item in
                            NavigationLink {
                                DetailView(item: item)
                            } label: {
                                MemoCardView(item: item)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    toggleCompleted(item)
                                } label: {
                                    Label(item.isCompleted ? "Offen" : "Erledigt", systemImage: item.isCompleted ? "circle" : "checkmark")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(item)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { offsets in
                            deleteItems(at: offsets, in: group.items)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var categoryFilterMenu: some View {
        Menu {
            Button {
                viewModel.selectedCategory = nil
            } label: {
                Label("Alle Kategorien", systemImage: viewModel.selectedCategory == nil ? "checkmark" : "line.3.horizontal.decrease.circle")
            }

            ForEach(MemoCategory.allCases) { category in
                Button {
                    viewModel.selectedCategory = category
                } label: {
                    Label(category.displayName, systemImage: viewModel.selectedCategory == category ? "checkmark" : category.systemImage)
                }
            }
        } label: {
            Label(viewModel.selectedCategory?.displayName ?? "Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Kategorie filtern")
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func deleteItems(at offsets: IndexSet, in sectionItems: [MemoItem]) {
        offsets.map { sectionItems[$0] }.forEach(delete)
    }

    private func toggleCompleted(_ item: MemoItem) {
        item.isCompleted.toggle()
        item.updatedAt = Date()

        Task { @MainActor in
            do {
                let notificationService = NotificationService()

                if item.isCompleted {
                    notificationService.removeNotification(for: item)
                } else if item.hasReminder {
                    try await notificationService.scheduleNotification(for: item)
                }
                try modelContext.save()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func delete(_ item: MemoItem) {
        Task { @MainActor in
            let notificationService = NotificationService()
            notificationService.removeNotification(for: item)
            imageStorage.delete(fileNames: item.imageFileNames)
            modelContext.delete(item)

            do {
                try modelContext.save()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: MemoItem.self, inMemory: true)
}
