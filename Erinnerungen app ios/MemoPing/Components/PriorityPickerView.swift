import SwiftUI

struct PriorityPickerView: View {
    @Binding var selection: MemoPriority

    var body: some View {
        Picker("Priorität", selection: $selection) {
            ForEach(MemoPriority.allCases) { priority in
                Label(priority.displayName, systemImage: priority.systemImage)
                    .tag(priority)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    PriorityPickerView(selection: .constant(.normal))
        .padding()
}
