import Foundation

extension FileManager {
    func removeDirectory(at path: String) {
        do {
            try removeItem(atPath: path)
        } catch CocoaError.fileNoSuchFile {
            return
        } catch {
            assertionFailure("Directory removing has failed for path: \(path). Error: \(error)")
        }
    }
}
