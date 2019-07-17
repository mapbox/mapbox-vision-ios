import Foundation

final class BatteryManager {
    private enum ConstantsBatteryLevel {
        static let fullyDischarged: Float = 0.0
        static let unavailable: Int8 = -1
    }

    private(set) var isCharging = false
    private(set) var batteryLevel: Int8 = -1

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(batteryStateDidChange(notification:)),
                                               name: UIDevice.batteryStateDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(batteryLevelDidChange(notification:)),
                                               name: UIDevice.batteryLevelDidChangeNotification,
                                               object: nil)
    }
}

extension BatteryManager {
    @objc
    func batteryStateDidChange(notification: NSNotification) {
        let batteryState = UIDevice.current.batteryState
        isCharging = (batteryState == .charging) || (batteryState == .full)
    }

    @objc
    func batteryLevelDidChange(notification: NSNotification) {
        let rawBatteryLevel = UIDevice.current.batteryLevel
        batteryLevel = (rawBatteryLevel >= ConstantsBatteryLevel.fullyDischarged) ? Int8(rawBatteryLevel * 100) : ConstantsBatteryLevel.unavailable
    }
}
