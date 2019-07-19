final class PerformanceProvider: NSObject {
    struct Dependencies {
        let reachability: Reachability
        let bluetoothManager: BluetoothManager
        let batteryManager: BatteryManager
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension PerformanceProvider: PerformanceProviderInterface {
    func batteryLevel() -> Int8 {
        return dependencies.batteryManager.batteryLevel
    }

    func isCharging() -> Bool {
        return dependencies.batteryManager.isCharging
    }

    func thermalState() -> ProcessInfo.ThermalState {
        return ProcessInfo.processInfo.thermalState
    }

    func isWifiEnabled() -> Bool {
        return dependencies.reachability.connection == .wifi
    }

    func isBluetoothEnabled() -> Bool {
        return dependencies.bluetoothManager.isBluetoothPoweredOn
    }

    func isCellularEnabled() -> Bool {
        return dependencies.reachability.connection == .cellular
    }
}
