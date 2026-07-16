import UIKit

enum ReferencePhotoStore {
    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("reference-bed.jpg")
    }

    @discardableResult
    static func save(_ image: UIImage) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return false }
        do {
            try data.write(to: fileURL, options: .atomic)
            SharedStore.hasReferencePhoto = true
            return true
        } catch {
            return false
        }
    }

    static func load() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
}
