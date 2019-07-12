import Foundation
@testable import MapboxVision

class MockSynchronizable: Synchronizable {
    weak var delegate: SyncDelegate?

    func sync() {}

    func stopSync() {}
}
