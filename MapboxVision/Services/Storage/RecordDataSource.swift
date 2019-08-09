import Foundation

protocol RecordDataSource {
    var baseURL: URL { get }
    var recordDirectories: [URL] { get }

    func removeFile(at url: URL)
}

extension RecordDataSource {
    var recordDirectories: [URL] {
        return baseURL.subDirectories
    }

    func removeFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

final class SyncRecordDataSource: RecordDataSource {
    var baseURL: URL {
        return URL(fileURLWithPath: DocumentsLocation.recordings(.other).path, isDirectory: true)
    }
}
