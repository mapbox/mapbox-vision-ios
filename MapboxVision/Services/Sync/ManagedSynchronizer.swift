import Foundation

final class ManagedSynchronizer: Synchronizable {
    struct Dependencies {
        let base: Synchronizable
        let reachability: Reachability
    }

    weak var delegate: SyncDelegate?

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

    // MARK: Public

    func set(dataSource: RecordDataSource) {
        dependencies.base.set(dataSource: dataSource)
    }

    func sync() {
        isExternallyAllowed = true
        continueSync()
    }

    func stopSync() {
        isExternallyAllowed = false
        pauseSync()
    }

    // MARK: Private

    private var isSyncAllowed: Bool {
        return isExternallyAllowed && dependencies.reachability.connection != .unavailable
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

extension ManagedSynchronizer: SyncDelegate {
    func syncStarted() {
        backgroundTask = UIApplication.shared.beginBackgroundTask()
    }

    func syncStopped() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
    }
}
