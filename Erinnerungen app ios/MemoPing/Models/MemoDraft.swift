import UIKit

struct MemoDraft {
    var title: String = ""
    var bodyText: String = ""
    var recognizedText: String = ""
    var images: [UIImage] = []
    var sourceType: MemoSourceType = .text
    var detectedInfo: DetectedInfo = DetectedInfo()
}
