import Foundation

final class FileSystem: NSObject {
    private let archiver: Archiver

    init(archiver: Archiver) {
        self.archiver = archiver
    }
}

extension FileSystem: FileSystemInterface {
    func archiveFiles(filePaths: [String], archivePath: String, callback: @escaping SuccessCallback) {
        DispatchQueue.global(qos: .utility).async {
            do {
                try self.archiver.archive(filePaths.map(URL.init(fileURLWithPath:)),
                                          destination: URL(fileURLWithPath: archivePath))
            } catch {
                assertionFailure("ERROR: archiving failed with error: \(error.localizedDescription)")
                callback(false)
                return
            }

            callback(true)
        }
    }
}
