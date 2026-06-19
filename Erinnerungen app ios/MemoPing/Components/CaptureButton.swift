import SwiftUI

struct CaptureButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(RemindlyStyle.elevatedFill)
                    .frame(width: 82, height: 82)
                    .shadow(color: RemindlyStyle.pink.opacity(0.28), radius: 22, y: 10)

                Circle()
                    .fill(RemindlyStyle.accentGradient)
                    .frame(width: 68, height: 68)

                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 88, height: 88)
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Neue Erinnerung oder Notiz erfassen")
        .accessibilityHint("Öffnet die Erfassung")
    }
}

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }
}

#Preview {
    CaptureButton {}
        .padding()
}
