import SwiftUI

struct PriorityPickerView: View {
    @Binding var selection: MemoPriority

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Priorität", systemImage: selection.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selection.tint)

            Picker("Priorität", selection: $selection) {
                ForEach(MemoPriority.allCases) { priority in
                    Text(priority.displayName)
                        .tag(priority)
                }
            }
            .pickerStyle(.segmented)
        }
        .accessibilityLabel("Priorität auswählen")
    }
}

#Preview {
    PriorityPickerView(selection: .constant(.normal))
        .padding()
}
