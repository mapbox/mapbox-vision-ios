/// Class that is responsible for collecting platform-specific metrics.
final class PerformanceProvider: NSObject {
    /// Structure that describes dependencies for `PerformanceProvider` class
    struct Dependencies {
        /// Manages the network connectivity. Is needed to collect the network status.
        let reachability: Reachability
        /// Manages the bluetooth module. Is needed to collect the state of bluetooth module.
        let bluetoothManager: BluetoothManager
        /// Manages the power state of the device. Is needed to collect the state of the battery.
        let batteryManager: BatteryManager
    }

    // MARK: Private properties

    /// Dependencies for `PerformanceProvider`.
    private let dependencies: Dependencies

    // MARK: Lifecycle

    /**
     Base initializer to create an instance of `PerformanceProvider`.

     - Parameters:
       - dependencies: Initialized dependencies for `PerformanceProvider`.
     */
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension PerformanceProvider: PerformanceProviderInterface {
    func batteryLevel() -> Int8 {
        return dependencies.batteryManager.batteryLevel()
    }

    func isCharging() -> Bool {
        return dependencies.batteryManager.isCharging()
    }

    func isWifiEnabled() -> Bool {
        return dependencies.reachability.connection == .wifi
    }

    func isBluetoothEnabled() -> Bool {
        return dependencies.bluetoothManager.isBluetoothPoweredOn()
    }

    func isCellularEnabled() -> Bool {
        return dependencies.reachability.connection == .cellular
    }
}
