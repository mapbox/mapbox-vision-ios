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
        coordinator.startRecording(referenceTime: 0, videoSettings: videoSettings) {
            XCTFail("Recording start has failed")
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
        coordinator.startRecording(referenceTime: 0, videoSettings: videoSettings) {}

        wait(for: [recordingStartedExpectation], timeout: 1)

        coordinator.stopRecording()

        wait(for: [recordingStoppedExpectation], timeout: 1)

        XCTAssert(!coordinator.isRecording, "Coordinator should not be recording after recording stop")

        let recordingPath = recordingStoppedExpectation.recordingPath.recordingPath
        XCTAssert(directoryExists(at: recordingPath), "Recording should be saved at \(recordingPath) after recording is stopped")
    }

    class TestClipRequest {
        let start: Float
        let end: Float

        init(start: Float, end: Float) {
            self.start = start
            self.end = end
        }
    }

    func testVideoClipping(withRequests requests: [TestClipRequest], _ message: String = "", line: UInt = #line) {
        let expectation = XCTestExpectation(description: "Wait for a big enough amount of time for record processing queue to finish its job")
        let videoSource = FakeVideoSource()
        videoSource.add(observer: coordinator)
        videoSource.start()
        coordinator.startRecording(referenceTime: 0, videoSettings: videoSettings) {}
        _ = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            print("Make \(requests.count) clip\(requests.count == 1 ? "" : "s")")
            requests.forEach {
                self.coordinator.makeClip(from: $0.start, to: $0.end)
            }

            _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                self.coordinator.stopRecording()

                _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    let path = "\(DocumentsLocation.currentRecording.path)"
                    let directoryContent = (try? FileManager.default.contentsOfDirectory(at: URL(string: path)!, includingPropertiesForKeys: nil, options: []))

                    if let directoryContent = directoryContent {
                        for file in directoryContent {
                            print("File \(file)")
                            if file.hasDirectoryPath {
                                let subDirectoryContent = (try? FileManager.default.contentsOfDirectory(at: file, includingPropertiesForKeys: nil, options: []))
                                if let subDirectoryContent = subDirectoryContent {
                                    let numberOfVideos = subDirectoryContent.filter {
                                        $0.pathExtension == "mp4"
                                    }
                                    .count

                                    XCTAssert(numberOfVideos == requests.count, message, line: line)
                                }
                            }
                        }
                    }
                    expectation.fulfill()
                }
            }
        }

        XCTWaiter().wait(for: [expectation], timeout: 20.0)
    }

    func testVideoClipping() {
        testVideoClipping(withRequests: [
            TestClipRequest(start: 1.0, end: 2.0),
            TestClipRequest(start: 1.5, end: 2.5),
            TestClipRequest(start: 0.0, end: 1.0),
            TestClipRequest(start: 3.0, end: 4.0),
            TestClipRequest(start: 3.0, end: 8.0)
        ], "Failed to clip videos from a chunk")
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

extension RecordCoordinator: VideoSourceObserver {
    public func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {
        self.handleFrame(videoSample.buffer)
    }
}
