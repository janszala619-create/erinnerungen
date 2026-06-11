import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Benachrichtigungen") {
                HStack {
                    Label("Status", systemImage: "bell")
                    Spacer()
                    Text(NotificationService.statusText(for: notificationStatus))
                        .foregroundStyle(.secondary)
                }

                Text("Erinnerungen werden als lokale iOS-Benachrichtigungen auf diesem iPhone geplant.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if notificationStatus == .denied {
                    Label("Benachrichtigungen sind deaktiviert.", systemImage: "bell.slash")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if notificationStatus == .notDetermined {
                    Label("Benachrichtigungen wurden noch nicht angefragt.", systemImage: "questionmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    requestNotifications()
                } label: {
                    Label("Benachrichtigungen erlauben", systemImage: "bell.badge")
                }
                .disabled(notificationStatus == .authorized)

                #if DEBUG
                Button {
                    scheduleDebugReminder()
                } label: {
                    Label("Test-Erinnerung in 10 Sekunden", systemImage: "timer")
                }
                #endif
            }

            Section("Datenschutz") {
                Label("MemoPing speichert deine Memos lokal auf deinem Gerät. Es gibt keinen Login, keine Cloud und kein Backend.", systemImage: "lock")
                Text("Spracherkennung wird über iOS bereitgestellt. Je nach Systemeinstellung kann Apple die Verarbeitung unterstützen. Deine gespeicherten Memos bleiben lokal auf deinem Gerät.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Standard-Kategorien") {
                ForEach(MemoCategory.allCases) { category in
                    Label(category.displayName, systemImage: category.systemImage)
                        .foregroundStyle(category.tint)
                }
            }

            Section("App-Info") {
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
            await refreshNotificationStatus()
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
        Task { @MainActor in
            do {
                let granted = try await NotificationService.shared.requestAuthorization()
                await refreshNotificationStatus()

                if !granted {
                    errorMessage = "Benachrichtigungen wurden nicht erlaubt. Erinnerungen können erst nach Aktivierung in den iOS-Einstellungen geplant werden."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func refreshNotificationStatus() async {
        notificationStatus = await NotificationService.shared.getAuthorizationStatus()
    }

    #if DEBUG
    private func scheduleDebugReminder() {
        Task { @MainActor in
            do {
                try await NotificationService.shared.scheduleDebugReminder()
                await refreshNotificationStatus()
                errorMessage = "Test-Erinnerung wurde für in 10 Sekunden geplant."
            } catch {
                await refreshNotificationStatus()
                errorMessage = error.localizedDescription
            }
        }
    }
    #endif
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
