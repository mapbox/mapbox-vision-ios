import XCTest

@testable import MapboxVision

class BaseVisionManagerTests: XCTestCase {
    var visionManager: BaseVisionManager!
    var dependencies: BaseDependencies!
    var synchronizer: MockSynchronizable!

    let otherDataSource = SyncRecordDataSource(region: .other)
    let chinaDataSource = SyncRecordDataSource(region: .china)

    override func setUp() {
        super.setUp()

        synchronizer = MockSynchronizable()
        dependencies = BaseDependencies(native: MockNative(), synchronizer: synchronizer)
        visionManager = BaseVisionManager(dependencies: dependencies)
    }

    // swiftlint:disable comma
    func testChangingCountries() {
        // Given
        let actions: [(Country, [MockSynchronizable.Action])] = [
            (.unknown , [.stopSync]),
            (.USA     , [.stopSync, .setDataSource(dataSource: otherDataSource), .sync]),
            (.UK      , []),
            (.china   , [.stopSync, .setDataSource(dataSource: chinaDataSource), .sync]),
            (.unknown , [.stopSync]),
        ]

        // When
        actions.compactMap { $0.0 }.forEach(visionManager.onCountryUpdated)

        // Then
        XCTAssertEqual(synchronizer.actionLog, Array(actions.compactMap { $0.1 }.joined()))
    }
}
