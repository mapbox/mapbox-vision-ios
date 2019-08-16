import XCTest

@testable import MapboxVision

final class RecordingTestExpectation<T>: XCTestExpectation {
    var recordingPath: T!

    func fulfill(with path: T) {
        recordingPath = path
        fulfill()
    }
}

final class RecordCoordinatorTests: XCTestCase {
    let videoSettings = VideoSettings(width: 960, height: 540, codec: .h264, fileType: .mp4, fileExtension: "mp4", bitRate: 6_000_000)
    var coordinator: RecordCoordinator!

    let recordingStartedExpectation = RecordingTestExpectation<String>(description: "Recording has been started")
    let recordingStoppedExpectation = RecordingTestExpectation<RecordingPath>(description: "Recording has been stopped")

    override func setUp() {
        super.setUp()

        let docLocations: [DocumentsLocation] = [.cache, .currentRecording, .recordings(.china), .recordings(.other)]
        docLocations.map { $0.path }.forEach(removeDirectory)

        coordinator = RecordCoordinator()
        coordinator.delegate = self
    }

    override func tearDown() {
        recordingStartedExpectation.recordingPath = nil
        coordinator = nil
        super.tearDown()
    }

    func testStart() {
        do {
            try coordinator.startRecording(referenceTime: 0, videoSettings: videoSettings)
        } catch {
            XCTFail("Recording start has failed with error: \(error)")
        }

        wait(for: [recordingStartedExpectation], timeout: 1)

        XCTAssert(coordinator.isRecording, "Coordinator should be recording after recording start")
        XCTAssert(directoryExists(at: DocumentsLocation.cache.path), "Cache should exist after recording is started")

        guard
            let path = RecordingPath(existing: recordingStartedExpectation.recordingPath, settings: videoSettings),
            directoryExists(at: path.recordingPath)
        else {
            XCTFail("Recording directory \(recordingStartedExpectation.recordingPath.debugDescription) should exist with created structure.")
            return
        }

        XCTAssert(directoryExists(at: path.imagesDirectoryPath), "\(path.imagesDirectoryPath) should exist")
    }

    func testStop() {
        try? coordinator.startRecording(referenceTime: 0, videoSettings: videoSettings)

        wait(for: [recordingStartedExpectation], timeout: 1)

        coordinator.stopRecording()

        wait(for: [recordingStoppedExpectation], timeout: 1)

        XCTAssert(!coordinator.isRecording, "Coordinator should not be recording after recording stop")

        let recordingPath = recordingStoppedExpectation.recordingPath.recordingPath
        XCTAssert(directoryExists(at: recordingPath), "Recording should be saved at \(recordingPath) after recording is stopped")
    }

    private func directoryExists(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func removeDirectory(at path: String) {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch CocoaError.fileNoSuchFile {
            return
        } catch {
            assertionFailure("Directory removing has failed for path: \(path). Error: \(error)")
        }
    }
}

extension RecordCoordinatorTests: RecordCoordinatorDelegate {
    func recordingStarted(path: String) {
        recordingStartedExpectation.fulfill(with: path)
    }

    func recordingStopped(recordingPath: RecordingPath) {
        recordingStoppedExpectation.fulfill(with: recordingPath)
    }
}
