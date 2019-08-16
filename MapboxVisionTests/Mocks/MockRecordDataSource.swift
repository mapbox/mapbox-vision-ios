import Foundation
@testable import MapboxVision

final class MockRecordDataSource: RecordDataSource {
    var baseURL: URL {
        return URL(fileURLWithPath: "")
    }

    var recordDirectories: [URL] = []
}
