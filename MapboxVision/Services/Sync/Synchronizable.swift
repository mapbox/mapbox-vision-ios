import Foundation

protocol SyncDelegate: AnyObject {
    func syncStarted()
    func syncStopped()
}

protocol Synchronizable: AnyObject {
    var delegate: SyncDelegate? { get set }

    func set(dataSource: RecordDataSource, baseURL: URL?)

    func sync()
    func stopSync()
}
