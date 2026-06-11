import SwiftUI

struct CategoryPickerView: View {
    @Binding var selection: MemoCategory?

    var body: some View {
        Picker("Kategorie", selection: $selection) {
            Label("Keine", systemImage: "tray")
                .tag(MemoCategory?.none)

            ForEach(MemoCategory.allCases) { category in
                Label(category.displayName, systemImage: category.systemImage)
                    .tag(Optional(category))
            }
        }
    }
}

#Preview {
    Form {
        CategoryPickerView(selection: .constant(.privat))
    }
}
