@testable import MapboxVision
import XCTest

class RecordingPathTests: XCTestCase {
    private let settings = VideoSettings.highQuality
    private let fileManager = FileManager.default

    override func setUp() {
        super.setUp()

        let locations: [DocumentsLocation] = [.cache, .currentRecording, .recordings(.other), .recordings(.china), .custom]
        locations.forEach { try? fileManager.removeItem(atPath: $0.path) }
    }

    func testMovingRecordingContents() {
        // Given
        let path = RecordingPath(basePath: .currentRecording, settings: settings)
        let testFile = "test.file"
        let testFilePath = path.recordingPath.appendingPathComponent(testFile)

        guard fileManager.createFile(atPath: testFilePath, contents: Data(base64Encoded: testFile)) else {
            XCTFail("Creation of \(testFilePath) has failed")
            return
        }

        // When
        let newPath: RecordingPath
        do {
            newPath = try path.move(to: .recordings(.other))
        } catch {
            XCTFail(error.localizedDescription)
            return
        }

        // Then
        let recPath = newPath.recordingPath.appendingPathComponent(testFile)
        XCTAssertTrue(fileManager.fileExists(atPath: recPath), "File should exist")
        XCTAssertFalse(fileManager.fileExists(atPath: testFilePath), "File should be moved")
    }

    func testMovingToExistingBasePath() {
        // Given
        let recordingsLocation = DocumentsLocation.recordings(.other)

        let path1 = RecordingPath(basePath: .currentRecording, directory: "one", settings: settings)
        XCTAssertNoThrow(try path1.move(to: recordingsLocation))
        let path2 = RecordingPath(basePath: .currentRecording, directory: "two", settings: settings)

        // When // Then
        XCTAssertNoThrow(try path2.move(to: recordingsLocation))
    }
}
