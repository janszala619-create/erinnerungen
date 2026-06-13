import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Memos", systemImage: "list.bullet")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Einstellungen", systemImage: "gear")
            }
        }
    }
}

#Preview {
    AppRootView()
        .modelContainer(for: MemoItem.self, inMemory: true)
}
