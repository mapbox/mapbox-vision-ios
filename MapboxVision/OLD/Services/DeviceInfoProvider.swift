import UIKit

protocol DeviceInfoProvidable {
    var id: String { get }
    var platformName: String { get }
    
    func reset()
}

final class DeviceInfoProvider: DeviceInfoProvidable {

    // MARK: Properties

    lazy var id: String = DeviceInfoProvider.generateID()
    let platformName: String = UIDevice.current.systemName

    // MARK: Private properties

    private var interruptionStartTime: Date? // TODO: remove

    // MARK: Public functions

    func reset() {
        id = DeviceInfoProvider.generateID()
    }

    // MARK: Private functions
    
    private static func generateID() -> String {
        return NSUUID().uuidString
    }
}
