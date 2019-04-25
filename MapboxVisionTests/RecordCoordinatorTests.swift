import XCTest

@testable import MapboxVision

final class RecordingStartedTestExpectation: XCTestExpectation {
    var recordingPath: String!

    func fulfill(with path: String) {
        recordingPath = path
        fulfill()
    }
}

final class RecordCoordinatorTests: XCTestCase {
    let videoSettings = VideoSettings(width: 960, height: 540, codec: .h264, fileType: .mp4, fileExtension: "mp4", bitRate: 6_000_000)
    var coordinator: RecordCoordinator!

    let recordingStartedExpectation = RecordingStartedTestExpectation(description: "Recording has been started")
    let recordingStoppedExpectation = XCTestExpectation(description: "Recording has been stopped")

    override func setUp() {
        super.setUp()

        let d: [DocumentsLocation] = [.cache, .currentRecording, .recordings]
        d.map { $0.path }.forEach(removeDirectory)

        coordinator = RecordCoordinator(settings: videoSettings)
        coordinator.delegate = self
    }

    override func tearDown() {
        recordingStartedExpectation.recordingPath = nil
        coordinator = nil
        super.tearDown()
    }

    func testRecordingCreation() {
        let location = DocumentsLocation.recordings.path
        XCTAssert(directoryExists(at: location), "\(location) should exist")
    }

    func testStart() {
        do {
            try coordinator.startRecording(referenceTime: 0)
        } catch {
            XCTFail("Recording start has failed with error: \(error)")
        }

        XCTAssert(coordinator.isRecording, "Coordinator should be recording after recording start")
        XCTAssert(directoryExists(at: DocumentsLocation.cache.path), "Cache should exist after recording is started")

        wait(for: [recordingStartedExpectation], timeout: 1)

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
        try? coordinator.startRecording(referenceTime: 0)

        wait(for: [recordingStartedExpectation], timeout: 1)

        coordinator.stopRecording()
        XCTAssert(!coordinator.isRecording, "Coordinator should not be recording after recording stop")

        wait(for: [recordingStoppedExpectation], timeout: 1)

        let finalPath = recordingStartedExpectation.recordingPath.replacingOccurrences(of: DocumentsLocation.currentRecording.rawValue,
                                                                                       with: DocumentsLocation.recordings.rawValue)

        XCTAssert(directoryExists(at: finalPath), "Recording should be moved to \(finalPath) after recording is stopped")
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

    func recordingStopped() {
        recordingStoppedExpectation.fulfill()
    }
}
