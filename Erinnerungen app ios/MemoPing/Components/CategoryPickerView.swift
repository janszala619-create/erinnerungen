import SwiftUI

struct CategoryPickerView: View {
    @Binding var selection: MemoCategory?

    var body: some View {
        Picker(selection: $selection) {
            Label("Keine Kategorie", systemImage: "tray")
                .tag(MemoCategory?.none)

            ForEach(MemoCategory.allCases) { category in
                Label(category.displayName, systemImage: category.systemImage)
                    .tag(Optional(category))
            }
        } label: {
            Label("Kategorie", systemImage: selection?.systemImage ?? "tray")
                .foregroundStyle(selection?.tint ?? .secondary)
        }
        .accessibilityLabel("Kategorie auswählen")
    }
}

#Preview {
    Form {
        CategoryPickerView(selection: .constant(.privat))
    }
}
