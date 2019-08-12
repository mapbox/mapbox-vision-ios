import Foundation
@testable import MapboxVision

class MockSynchronizable: Synchronizable {
    enum Action: Equatable {
        case sync
        case stopSync
        case set(dataSource: RecordDataSource, baseURL: URL?)

         static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.sync, .sync):
                return true
            case (.stopSync, .stopSync):
                return true
            case let (.set(rhsDataSource, rhsBaseURL),
                      .set(lhsDataSource, lhsBaseURL)):
                return rhsDataSource.baseURL == lhsDataSource.baseURL && rhsBaseURL == lhsBaseURL
            default:
                return false
            }
        }
    }

    private(set) var actionLog = [Action]()

    weak var delegate: SyncDelegate?

    func set(dataSource: RecordDataSource, baseURL: URL?) {
        actionLog.append(.set(dataSource: dataSource, baseURL: baseURL))
    }

    func sync() {
        actionLog.append(.sync)
    }

    func stopSync() {
        actionLog.append(.stopSync)
    }
}
