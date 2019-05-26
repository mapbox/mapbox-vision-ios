import Foundation

protocol SyncDelegate: AnyObject {
    func syncStarted()
    func syncStopped()
}

protocol Synchronizable: AnyObject {
    var delegate: SyncDelegate? { get set }
    
    func sync()
    func stopSync()
}
