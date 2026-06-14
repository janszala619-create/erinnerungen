import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var iCloudState: ICloudAccountState = .couldNotDetermine
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

            Section("iCloud Sync") {
                HStack {
                    Label("Status", systemImage: "icloud")
                    Spacer()
                    Text(iCloudState.displayText)
                        .foregroundStyle(iCloudState == .available ? Color.green : Color.secondary)
                }

                Text("MemoPing synchronisiert Memos über iCloud, wenn iCloud auf diesem Gerät aktiviert ist.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(iCloudState.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                #if DEBUG
                Text(ICloudSyncService.cloudKitContainerIdentifier)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                #endif
            }

            Section("Datenschutz") {
                Label("Die Synchronisation läuft über Apples iCloud/CloudKit. MemoPing verwendet keinen eigenen Server.", systemImage: "lock")
                Text("Spracherkennung wird über iOS bereitgestellt. Bilder bleiben in dieser Version als lokale Dateien auf dem jeweiligen Gerät gespeichert.")
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
            await refreshICloudStatus()
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

    private func refreshICloudStatus() async {
        iCloudState = await ICloudSyncService.shared.accountState()
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
