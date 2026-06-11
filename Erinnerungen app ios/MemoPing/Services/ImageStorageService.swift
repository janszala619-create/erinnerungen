import UIKit

enum ImageStorageError: LocalizedError {
    case cannotCreateData
    case cannotLoadDirectory

    var errorDescription: String? {
        switch self {
        case .cannotCreateData:
            return "Das Bild konnte nicht gespeichert werden."
        case .cannotLoadDirectory:
            return "Der lokale Bildspeicher konnte nicht vorbereitet werden."
        }
    }
}

final class ImageStorageService {
    private let folderName = "MemoPingImages"

    func save(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.86) ?? image.pngData() else {
            throw ImageStorageError.cannotCreateData
        }

        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = try imageDirectory().appendingPathComponent(fileName)
        try data.write(to: fileURL, options: [.atomic])
        return fileName
    }

    func load(fileName: String) -> UIImage? {
        guard let directory = try? imageDirectory() else {
            return nil
        }

        return UIImage(contentsOfFile: directory.appendingPathComponent(fileName).path)
    }

    func delete(fileName: String) {
        guard let directory = try? imageDirectory() else {
            return
        }

        try? FileManager.default.removeItem(at: directory.appendingPathComponent(fileName))
    }

    func delete(fileNames: [String]) {
        fileNames.forEach(delete(fileName:))
    }

    private func imageDirectory() throws -> URL {
        guard let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw ImageStorageError.cannotLoadDirectory
        }

        var directory = supportDirectory.appendingPathComponent(folderName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? directory.setResourceValues(values)
        }

        return directory
    }
}
