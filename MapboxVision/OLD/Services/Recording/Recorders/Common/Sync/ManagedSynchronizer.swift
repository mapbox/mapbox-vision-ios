import Foundation

final class ManagedSynchronizer {
    struct Dependencies {
        let base: Synchronizable
        let reachability: Reachability
    }

    // MARK: - Properties

    weak var delegate: SyncDelegate?

    // MARK: - Private properties
    
    private let dependencies: Dependencies
    
    private var isExternallyAllowed = false
    private var backgroundTask = UIBackgroundTaskIdentifier.invalid
    
    // MARK: Initialization

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        
        self.delegate = dependencies.base.delegate
        dependencies.base.delegate = self
    
        dependencies.reachability.whenReachable = { [weak self] _ in
            self?.continueSync()
        }
        dependencies.reachability.whenUnreachable = { [weak self] _ in
            self?.pauseSync()
        }
    
        try? dependencies.reachability.startNotifier()
    }
    
    // MARK: Private
    
    private var isSyncAllowed: Bool {
        return isExternallyAllowed && dependencies.reachability.connection != .none
    }
    
    private func continueSync() {
        guard isSyncAllowed else {
            pauseSync()
            return
        }
        dependencies.base.sync()
    }
    
    private func pauseSync() {
        dependencies.base.stopSync()
    }
}

extension ManagedSynchronizer: Synchronizable {
    func sync() {
        isExternallyAllowed = true
        continueSync()
    }

    func stopSync() {
        isExternallyAllowed = false
        pauseSync()
    }
}

extension ManagedSynchronizer: SyncDelegate {
    func syncStarted() {
        backgroundTask = UIApplication.shared.beginBackgroundTask()
    }
    
    func syncStopped() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
    }
}
