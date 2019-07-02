import XCTest

@testable import MapboxVision

final class DeviceInfoProviderTests: XCTestCase {
    func testIDReset() {
        let deviceInfo = DeviceInfoProvider()
        let initialID = deviceInfo.id

        deviceInfo.reset()

        XCTAssertNotEqual(initialID, deviceInfo.id)
    }
}
