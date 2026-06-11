import SwiftUI

struct CaptureButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(.blue, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Neue Erinnerung oder Notiz erfassen")
    }
}

#Preview {
    CaptureButton {}
        .padding()
}
