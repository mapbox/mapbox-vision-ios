@testable import MapboxVision
import XCTest

class VisionManagerTests: XCTestCase {
    var visionManager: VisionManager!
    var dependencies: VisionDependencies!
    var recorder: MockSessionRecorder!

    override func setUp() {
        super.setUp()

        recorder = MockSessionRecorder()
        dependencies = VisionDependencies(
            native: MockNative(),
            synchronizer: MockSynchronizable(),
            recorder: recorder,
            dataProvider: MockDataProvider(),
            deviceInfo: DeviceInfoProvider()
        )

        self.visionManager = VisionManager(dependencies: dependencies!, videoSource: MockVideoSource())
    }

    // MARK: - Destroy

    func testNoCrashOnVisionManagerDeallocWithoutDestroy() {
        // We called destroy in destructors of VisionManager, BaseVisionManager, VisionManagerNative and VisionManagerBaseNative,
        // so VisionManagerBaseNative's destroy method called multiple times, so we tried to destroy already destroyed resources,
        // which caused an EXC_BAD_ACCESS.

        // Given
        // object of VisionManager

        // When
        // we deallocate it without destroy

        // Then
        // Shouldn't be any error and method destroy() should be called for VisionManagerNative
        XCTAssertNoThrow(
            self.visionManager = nil,
            "VisionManager should be successfully deallocated releasing the object without calling destroy"
        )
        XCTAssertTrue(
            (dependencies?.native as? MockNative)?.isDestroyed ?? false,
            "Method destroy() should be called for BaseVisionManager"
        )
    }

    func testNoCrashOnVisionManagerDeallocAfterDestroy() {
        // Given
        // object of VisionManager with called destroy()
        self.visionManager?.destroy()

        // When
        // release the instance of VisionManager

        // Then
        // shouldn't be any error
        XCTAssertNoThrow(
            self.visionManager = nil,
            "VisionManager should be successfully deallocated after calling destroy and releasing the object"
        )
    }

    // MARK: - Recording

    func testVisionManagerDoesNotRecordOnCountryChangeWhenNotStarted() {
        // Given
        // VisionManager with default country

        // When
        visionManager.onCountryUpdated(.USA)
        visionManager.onCountryUpdated(.UK)
        visionManager.onCountryUpdated(.china)
        visionManager.onCountryUpdated(.other)
        visionManager.onCountryUpdated(.unknown)

        // Then
        XCTAssert(recorder.actionsLog.isEmpty, "VisionManager should not record when not started.")
    }

    func testVisionManagerRecordsDataInTheRightWayForCorrespondingCountries() {
        // Given
        // VisionManager with default country

        // When
        // VisionManager is started
        visionManager.start()

        // We set countries
        visionManager.onCountryUpdated(.USA)
        visionManager.onCountryUpdated(.UK)
        visionManager.onCountryUpdated(.china)
        visionManager.onCountryUpdated(.other)
        visionManager.onCountryUpdated(.unknown)

        // Then
        // VisionManager is expected to start internal recording on its start, not react to country update
        // if synchronization region isn't changed, stop internal recording and start it again if the synchronization region is changed
        let expectedActions: [MockSessionRecorder.Action] = [
            .startInternal, // initial
            // nothing      // USA
            // nothing,     // UK
            .stop,          // China
            .startInternal,
            .stop,          // other
            .startInternal,
            .stop,          // unknown
            .startInternal,
        ]

        XCTAssert(
            recorder.actionsLog.elementsEqual(expectedActions),
            """
            Internal recording doesn't react correctly to country change.
            SessionRecorder's action log: \(recorder.actionsLog) doesn't match expected one: \(expectedActions)
            """
        )
    }

    func testVisionManagerRecordsDataInTheRightWayForCorrespondingCountriesWithExternalRecordingEnabled() {
        // Given
        // VisionManager with default country

        // When
        // VisionManager is started
        visionManager.start()

        // External recording is started
        try? visionManager.startRecording(to: "")

        // We set countries
        visionManager.onCountryUpdated(.USA)
        visionManager.onCountryUpdated(.UK)
        visionManager.onCountryUpdated(.china)
        visionManager.onCountryUpdated(.other)
        visionManager.onCountryUpdated(.unknown)

        // Then
        // VisionManager should not stop external recording if country is changed
        let expectedActions: [MockSessionRecorder.Action] = [
            .startInternal,
            .stop,
            .startExternal(withPath: ""),
        ]

        XCTAssert(
            recorder.actionsLog.elementsEqual(expectedActions),
            """
            External recording doesn't react correctly to country change.
            SessionRecorder's action log: \(recorder.actionsLog) doesn't match expected one: \(expectedActions)
            """
        )
    }

    func testVisionManagerStopsInternalRecordingOnStop() {
        // Given
        // VisionManager

        // When
        visionManager.start()
        visionManager.stop()

        // Then
        let expectedActions: [MockSessionRecorder.Action] = [
            .startInternal,
            .stop,
        ]

        XCTAssert(
            recorder.actionsLog.elementsEqual(expectedActions),
            """
            Internal recording doesn't react correctly to VisionManager start and stop.
            SessionRecorder's action log: \(recorder.actionsLog) doesn't match expected one: \(expectedActions)
            """
        )
    }

    func testVisionManagerStopsExternalRecordingOnStop() {
        // Given
        // VisionManager

        // When
        visionManager.start()
        try? visionManager.startRecording(to: "")
        visionManager.stop()

        // Then
        let expectedActions: [MockSessionRecorder.Action] = [
            .startInternal,
            .stop,
            .startExternal(withPath: ""),
            .stop,
        ]

        XCTAssert(
            recorder.actionsLog.elementsEqual(expectedActions),
            """
            External recording doesn't react correctly to VisionManager start and stop.
            SessionRecorder's action log: \(recorder.actionsLog) doesn't match expected one: \(expectedActions)
            """
        )
    }

    func testVisionManagerStopsAllRecordingOnStop() {
        // Given
        // VisionManager

        // When
        visionManager.start()
        try? visionManager.startRecording(to: "")
        visionManager.stopRecording()
        visionManager.stop()

        // Then
        let expectedActions: [MockSessionRecorder.Action] = [
            .startInternal,
            .stop,
            .startExternal(withPath: ""),
            .stop,
            .startInternal,
            .stop
        ]

        XCTAssert(
            recorder.actionsLog.elementsEqual(expectedActions),
            """
            Recording doesn't react correctly to VisionManager start, stop and single external recording request.
            SessionRecorder's action log: \(recorder.actionsLog) doesn't match expected one: \(expectedActions)
            """
        )
    }
}
