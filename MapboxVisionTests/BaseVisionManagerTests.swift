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

    func testChangingCountries() {
        // Given
        let actions: [(Country, [MockSynchronizable.Action])] = [
            (.unknown, [.stopSync]),
            (.USA, [
                .stopSync,
                .set(dataSource: otherDataSource, baseURL: URL(string: Constants.URL.defaultEventsEndpoint)!),
                .sync
            ]),
            (.UK, []),
            (.china, [
                .stopSync,
                .set(dataSource: chinaDataSource, baseURL: URL(string: Constants.URL.chinaEventsEndpoint)!),
                .sync
            ]),
            (.unknown, [.stopSync]),
        ]

        // When
        actions.compactMap { $0.0 }.forEach(visionManager.onCountryUpdated)

        // Then
        XCTAssertEqual(synchronizer.actionLog, Array(actions.compactMap { $0.1 }.joined()))
    }
}
