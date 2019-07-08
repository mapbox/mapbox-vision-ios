protocol DeviceInfoProvidable {
    var id: String { get }
    var platformName: String { get }
}

final class DeviceInfoProvider: DeviceInfoProvidable {
    private enum Keys {
        static let uniqueDeviceIdKey = "uniqueDeviceIdKey"
    }

    lazy var id: String = {
        let defaults = UserDefaults.standard

        if let uuid = defaults.object(forKey: Keys.uniqueDeviceIdKey) as? String {
            return uuid
        } else {
            let uuid = NSUUID().uuidString
            defaults.set(uuid, forKey: Keys.uniqueDeviceIdKey)
            return uuid
        }
    }()

    let platformName: String = UIDevice.current.systemName
}
