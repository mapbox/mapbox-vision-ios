import Foundation
@testable import MapboxVision

class MockSynchronizable: Synchronizable {
    enum Action: Equatable {
        case sync
        case stopSync
        case setDataSource(dataSource: RecordDataSource)

        static func ==(lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.sync, .sync):
                return true
            case (.stopSync, .stopSync):
                return true
            case let (.setDataSource(rhsDataSource), .setDataSource(lhsDataSource)):
                return rhsDataSource.baseURL == lhsDataSource.baseURL
            default:
                return false
            }
        }
    }

    private(set) var actionLog = [Action]()

    weak var delegate: SyncDelegate?

    func set(dataSource: RecordDataSource) {
        actionLog.append(.setDataSource(dataSource: dataSource))
    }

    func sync() {
        actionLog.append(.sync)
    }

    func stopSync() {
        actionLog.append(.stopSync)
    }
}
