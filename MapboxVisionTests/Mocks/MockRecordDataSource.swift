import Foundation
@testable import MapboxVision

final class MockRecordDataSource: RecordDataSource {
    var removedFiles: [URL] = []

    var baseURL: URL {
        return URL(fileURLWithPath: "")
    }

    var recordDirectories: [URL] = []

    func removeFile(at url: URL) {
        removedFiles.append(url)
    }
}
