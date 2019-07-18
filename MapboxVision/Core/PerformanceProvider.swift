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
