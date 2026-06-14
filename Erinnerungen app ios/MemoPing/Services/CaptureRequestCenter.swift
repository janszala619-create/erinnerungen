import Combine
import Foundation

@MainActor
final class CaptureRequestCenter: ObservableObject {
    static let shared = CaptureRequestCenter()

    @Published var isCapturePresented = false

    private init() {}

    func requestCapture() {
        isCapturePresented = true
    }
}
