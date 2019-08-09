import Foundation
@testable import MapboxVision

class MockSynchronizable: Synchronizable {
    weak var delegate: SyncDelegate?

    func set(dataSource: RecordDataSource) {}

    func sync() {}

    func stopSync() {}
}
