@testable import MapboxVision
import XCTest

class VisionManagerTests: XCTestCase {
    var visionManager: VisionManager!
    var dependencies: VisionDependencies!

    override func setUp() {
        super.setUp()

        let fileManager = FileManager.default
        let docLocations: [DocumentsLocation] = [.cache, .currentRecording, .recordings(.china), .recordings(.other)]
        docLocations.map { $0.path }.forEach(fileManager.removeDirectory)

        dependencies = VisionDependencies(
            native: MockNative(),
            recorder: MockFrameRecorder(),
            dataProvider: MockDataProvider()
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
}
