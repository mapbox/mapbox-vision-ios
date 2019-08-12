import Foundation

@testable import MapboxVision

final class ClosureSyncDelegate: SyncDelegate {
    var onSyncStarted: (() -> Void)?
    var onSyncStopped: (() -> Void)?
    
    func syncStarted() {
        onSyncStarted?()
    }
    
    func syncStopped() {
        onSyncStopped?()
    }
}
