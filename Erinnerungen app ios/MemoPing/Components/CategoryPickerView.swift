import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectionRawValue: String?
    let categories: [MemoCategoryItem]

    var body: some View {
        let selectedCategory = MemoCategoryItem.item(for: selectionRawValue, in: categories)

        Picker(selection: $selectionRawValue) {
            Label("Keine Kategorie", systemImage: "tray")
                .tag(String?.none)

            ForEach(sortedCategories, id: \.id) { category in
                Label(category.displayName, systemImage: category.systemImage)
                    .tag(Optional(category.id))
            }
        } label: {
            Label("Kategorie", systemImage: selectedCategory?.systemImage ?? "tray")
                .foregroundStyle(selectedCategory?.tint ?? .secondary)
        }
        .accessibilityLabel("Kategorie auswählen")
    }

    private var sortedCategories: [MemoCategoryItem] {
        categories.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }

            return $0.sortOrder < $1.sortOrder
        }
    }
}

#Preview {
    Form {
        CategoryPickerView(
            selectionRawValue: .constant("privat"),
            categories: [
                MemoCategoryItem(id: "privat", name: "Privat", systemImage: "person", tintRawValue: "green", isDefault: true)
            ]
        )
    }
}
