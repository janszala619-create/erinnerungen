import SwiftUI

struct SettingsView: View {
    @StateObject private var notificationService = NotificationService()
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Benachrichtigungen") {
                HStack {
                    Label("Status", systemImage: "bell")
                    Spacer()
                    Text(notificationService.statusText)
                        .foregroundStyle(.secondary)
                }

                Button {
                    requestNotifications()
                } label: {
                    Label("Berechtigung anfragen", systemImage: "bell.badge")
                }
            }

            Section("Datenschutz") {
                Label("Alle Daten bleiben lokal auf diesem Gerät.", systemImage: "lock")
                Label("Kein Login, keine Cloud, kein Backend, keine externe API.", systemImage: "network.slash")
            }

            Section("Kategorien") {
                ForEach(MemoCategory.allCases) { category in
                    Label(category.displayName, systemImage: category.systemImage)
                        .foregroundStyle(category.tint)
                }
            }

            Section("App") {
                HStack {
                    Text("MemoPing")
                    Spacer()
                    Text("Version 1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Einstellungen")
        .task {
            await notificationService.refreshAuthorizationStatus()
        }
        .alert("Hinweis", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func requestNotifications() {
        Task {
            do {
                _ = try await notificationService.requestAuthorization()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
