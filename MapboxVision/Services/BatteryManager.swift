import Foundation

/// Class that contains logic to dispatch and manage the battery state of the device.
final class BatteryManager {
    /// Constants that represents significant battery power states.
    private enum ConstantsBatteryLevel {
        /// The value that corresponds to fully discharged battery (the device might be still powered on).
        static let fullyDischarged: Float = 0.0
        /// The value that corresponds to situation when battery state is unknown or battery monitoring is not enabled.
        static let unavailable: Int8 = -1
    }

    // MARK: Public properties

    /// Indicates whether battery is currently charging or not.
    var isCharging: Bool {
        let batteryState = UIDevice.current.batteryState
        return (batteryState == .charging) || (batteryState == .full)
    }

    /// Battery level in range from 0 (fully discharged) to 100 (100% charged). In case when battery level can't be collected the return value is -1.
    var batteryLevel: Int8 {
        let rawBatteryLevel = UIDevice.current.batteryLevel
        return (rawBatteryLevel >= ConstantsBatteryLevel.fullyDischarged) ? Int8(rawBatteryLevel * 100) : ConstantsBatteryLevel.unavailable
    }

    // MARK: Lifecycle

    /**
     Base initializer to create an instance of `BatteryManager`.
     */
    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
}
