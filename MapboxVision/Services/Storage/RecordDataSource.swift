import Foundation

protocol RecordDataSource {
    var baseURL: URL { get }
    var recordDirectories: [URL] { get }
}

extension RecordDataSource {
    var recordDirectories: [URL] {
        return baseURL.subDirectories
    }
}

final class SyncRecordDataSource: RecordDataSource {
    var baseURL: URL {
        return URL(fileURLWithPath: DocumentsLocation.recordings(.other).path, isDirectory: true)
    }
}
