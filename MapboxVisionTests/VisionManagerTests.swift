@testable import MapboxVision
import XCTest

class VisionManagerTests: XCTestCase {
    var visionManager: VisionManager?
    var dependencies: VisionDependencies?

    override func setUp() {
        super.setUp()

        dependencies = VisionDependencies(
            native: MockNative(),
            synchronizer: MockSynchronizable(),
            recorder: MockSessionRecorder(),
            dataProvider: MockDataProvider(),
            deviceInfo: DeviceInfoProvider()
        )

        self.visionManager = VisionManager(dependencies: dependencies!, videoSource: MockVideoSource())
    }

    func testAssertOnVisionManagerDeallocWithoutDestroy() {
        // We called destroy in destructors of VisionManager, BaseVisionManager, VisionManagerNative and VisionManagerBaseNative,
        // so VisionManagerBaseNative's destroy method called multiple times, so we tried to destroy already destroyed resources,
        // which caused an EXC_BAD_ACCESS.

        // Nevertheless the logic was sort of right, it should do assertFailure on deinit without destroy was called

        // Given
        // object of VisionManager

        // When
        // we deallocate it without destroy

        // Then
        // Should be assertion failure
        AssertFailure(
            self.visionManager = nil,
            "VisionManager should call assertioFailure when we release the object without calling destroy"
        )
    }

    func testNoAssertOnVisionManagerDeallocAfterDestroy() {
        // Given
        // object of VisionManager with called destroy()
        self.visionManager?.destroy()

        // When
        // release the instance of VisionManager

        // Then
        // Shouldn't be assertion failure
        AssertNoFailure(
            self.visionManager = nil,
            "VisionManager should be successfully deallocated after calling destroy and releasing the object"
        )
    }

    func testVisionManagerRecordsDataInTheRightWayForCorrespondingCountries() {
        // Given
        // VisionManager with default country
        guard let visionManager = self.visionManager, let recorder = dependencies?.recorder as? MockSessionRecorder else {
            XCTFail("Configured environment doesn't fit test case")
            return
        }

        // When
        // We set countries
        visionManager.onCountryUpdated(.USA)
        visionManager.onCountryUpdated(.UK)
        visionManager.onCountryUpdated(.china)
        visionManager.onCountryUpdated(.other)
        visionManager.onCountryUpdated(.unknown)

        // Then
        // we expect that visionManager will call SessionRecorder's method `startInternal` for all countries but China and that there
        // will no be any other calls to SessionRecorder. For China we expect `stop` method to be called
        let expectedActions: [MockSessionRecorder.Action] = [
            .startInternal, // USA
            .startInternal, // UK
            .stop,          // China
            .startInternal, // other
            .startInternal  // unknown
        ]

        XCTAssert(
            recorder.actionsLog.elementsEqual(expectedActions),
            "VisionManager should call SessionRecorder's method `startInternal` for all countries but China"
        )
    }

    func testVisionManagerRecordsDataInTheRightWayForCorrespondingCountriesWithExternalRecordingEnabled() {
        // Given
        // VisionManager with default country which is in external recording mode
        guard let visionManager = self.visionManager, let recorder = dependencies?.recorder as? MockSessionRecorder else {
            XCTAssert(false)
            return
        }

        visionManager.start()
        try? visionManager.startRecording(to: "")

        // When
        // We set countries
        visionManager.onCountryUpdated(.USA)
        visionManager.onCountryUpdated(.UK)
        visionManager.onCountryUpdated(.china)
        visionManager.onCountryUpdated(.other)
        visionManager.onCountryUpdated(.unknown)

        // Then
        // we expect that visionManager will stop external recording and start internal for all countries but China. For China it
        // should just stop recording. In any case, it shouldn't resume external recording
        let expectedActions: [MockSessionRecorder.Action] = [
            .startInternal,
            .stop,
            .startExternal(withPath: ""),
            .startInternal,
            .startInternal,
            .stop,
            .startInternal,
            .startInternal
        ]

        XCTAssert(
            recorder.actionsLog.elementsEqual(expectedActions),
            "VisionManager should stop external recording after setting a new country and start internal for all countries but China"
        )

        visionManager.stopRecording()
        visionManager.stop()
    }
}
