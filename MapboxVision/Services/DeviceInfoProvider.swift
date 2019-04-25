import UIKit

protocol DeviceInfoProvidable {
    var id: String { get }
    var platformName: String { get }

    func reset()
}

final class DeviceInfoProvider: DeviceInfoProvidable {
    lazy var id: String = DeviceInfoProvider.generateID()
    let platformName: String = UIDevice.current.systemName

    private var interruptionStartTime: Date?

    func reset() {
        id = DeviceInfoProvider.generateID()
    }

    private static func generateID() -> String {
        return NSUUID().uuidString
    }
}
