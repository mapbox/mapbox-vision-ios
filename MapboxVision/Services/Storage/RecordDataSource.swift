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
    private let region: SyncRegion
    
    init(region: SyncRegion) {
        self.region = region
    }

    var baseURL: URL {
        return URL(fileURLWithPath: DocumentsLocation.recordings(region).path, isDirectory: true)
    }
}
