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

    func testVideoClipping() {
        // Given
        // a list of clip requests
        // When
        // we try to make clips with them
        // Then
        // we should get the same number of video files on filesystem
        performVideoClipping(with: [
            TestClipRequest(start: 1.0, end: 2.0),
            TestClipRequest(start: 1.5, end: 2.5),
            TestClipRequest(start: 0.0, end: 1.0),
            TestClipRequest(start: 3.0, end: 4.0),
            TestClipRequest(start: 3.0, end: 8.0)
        ], "Failed to clip videos from a chunk")
    }

    func testSessionRestarting() {
        let expectation = XCTestExpectation(description: "All the recording sessions are finished")
        let internalSessionDuration = 0.5
        let externalSessionDuration = 1.0

        // Given
        // SessionRecorder
        let sessionRecorder = SessionRecorder(dependencies: SessionRecorder.Dependencies(
            recorder: coordinator,
            sessionManager: SessionManager(),
            videoSettings: self.videoSettings,
            getSeconds: { 0.0 },
            startSavingSession: { _ in },
            stopSavingSession: { }
        ))

        var didCreateExternalFolder = false
        let testFolderPath = DocumentsLocation.cache.path.appendingPathComponent("test", isDirectory: true)

        let recordDelegate = RecordDelegate()
        recordDelegate.onRecordingStopped = { recordingPath in
            if recordingPath.recordingPath.absolutePath == testFolderPath.absolutePath {
                didCreateExternalFolder = true
                expectation.fulfill()
            }
        }
        sessionRecorder.delegate = recordDelegate
        let videoSource = MockVideoSource()
        videoSource.add(observer: sessionRecorder)
        videoSource.start()
        sessionRecorder.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + internalSessionDuration) {
            // When
            // we manually restart session
            sessionRecorder.stop()
            sessionRecorder.start(mode: .external(path: testFolderPath))

            DispatchQueue.main.asyncAfter(deadline: .now() + externalSessionDuration) {
                sessionRecorder.stop()
            }
        }

        wait(for: [expectation], timeout: 2.0)

        // Then
        // session files should be created for the session
        XCTAssert(didCreateExternalFolder, "External session wasn't recorded")
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

    private class TestClipRequest {
        let start: Float
        let end: Float

        init(start: Float, end: Float) {
            self.start = start
            self.end = end
        }
    }

    private class RecordDelegate: RecordCoordinatorDelegate {
        var onRecordingStarted: ((String) -> Void)?
        var onRecordingStopped: ((RecordingPath) -> Void)?

        func recordingStarted(path: String) {
            onRecordingStarted?(path)
        }

        func recordingStopped(recordingPath: RecordingPath) {
            onRecordingStopped?(recordingPath)
        }
    }

    private func performVideoClipping(with requests: [TestClipRequest], _ message: String = "", line: UInt = #line) {
        let expectation = XCTestExpectation(description: "Recording has been stopped")
        let recordDurationBeforeClipRequests = 4.0
        let recordDurationAfterClipRequests = 1.0
        let videoSource = MockVideoSource()
        videoSource.add(observer: coordinator)
        videoSource.start()

        var didCreateAllClips = false

        let recordDelegate = RecordDelegate()
        recordDelegate.onRecordingStopped = { path in
            if let pathUrl = URL(string: path.recordingPath) {
                let directoryContent = try? FileManager.default.contentsOfDirectory(at: pathUrl, includingPropertiesForKeys: nil, options: [])

                if let directoryContent = directoryContent {
                    let numberOfVideos = directoryContent.filter {
                        $0.pathExtension == path.settings.fileExtension
                    }
                    .count

                    didCreateAllClips = numberOfVideos == requests.count
                }
            }
            expectation.fulfill()
        }

        coordinator.delegate = recordDelegate
        coordinator.startRecording(referenceTime: 0, videoSettings: videoSettings) {}
        DispatchQueue.main.asyncAfter(deadline: .now() + recordDurationBeforeClipRequests) { [unowned self] in
            requests.forEach {
                self.coordinator.makeClip(from: $0.start, to: $0.end)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + recordDurationAfterClipRequests) { [unowned self] in
                self.coordinator.stopRecording()
            }
        }

        wait(for: [expectation], timeout: 10.0)

        XCTAssert(didCreateAllClips, message, line: line)
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
        handleFrame(videoSample.buffer)
    }
}

extension SessionRecorder: VideoSourceObserver {
    public func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {
        handleFrame(videoSample.buffer)
    }
}

extension String {
    var absolutePath: String {
        return nsString.resolvingSymlinksInPath
    }
}
