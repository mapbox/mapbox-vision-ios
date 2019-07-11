@testable import MapboxVision
import XCTest

final class DeviceInfoProviderTests: XCTestCase {
    func testIdReturnsPersistentUUIDBetweenCalls() {
        // Given
        let deviceInfoProvider = DeviceInfoProvider()
        let initialUUID = deviceInfoProvider.id

        // When
        let nextUUID = deviceInfoProvider.id

        // Then
        XCTAssertEqual(initialUUID, nextUUID)
    }

    func testIdReturnsPersistentUUIDBetweenSessions() {
        // Given
        let firstDeviceInfoProvider = DeviceInfoProvider()
        let initialUUID = firstDeviceInfoProvider.id

        // When
        let secondDeviceInfoProvider = DeviceInfoProvider()
        let nextUUID = secondDeviceInfoProvider.id

        // Then
        XCTAssertEqual(initialUUID, nextUUID)
    }

    func testPlatfromNameReturnsIOSOnIOSDevices() {
        // Given
        let deviceInfoProvider = DeviceInfoProvider()
        let expectedPlatformName = "iOS"

        // When
        let platformName = deviceInfoProvider.platformName

        // Then
        XCTAssertEqual(platformName, expectedPlatformName)
    }
}
