import XCTest

@testable import MapboxVision

class RecordSynchronizerTests: XCTestCase {
    enum TestExpectation {
        static let positiveScenario = XCTestExpectation(description: "Positive scenario")
        static let emptyRecordDirIsRemoved = XCTestExpectation(description: "Empty record directory is removed")
        static let oldestRecordDirIsRemoved = XCTestExpectation(description: "Oldest record directory is removed")
    }

    enum RecordDirName {
        static let first = "/1"
        static let second = "/2"
        static let empty = "/3"
    }

    typealias File = MockFileManager.File

    let data = [
        URL(fileURLWithPath: RecordDirName.first, isDirectory: true): [
            File(url: URL(fileURLWithPath: "\(RecordDirName.first)/gps.bin"), size: 20),
            File(url: URL(fileURLWithPath: "\(RecordDirName.first)/videos.json"), size: 3),
            File(url: URL(fileURLWithPath: "\(RecordDirName.first)/1.mp4"), size: 1),
            File(url: URL(fileURLWithPath: "\(RecordDirName.first)/2.mp4"), size: 1),
            File(url: URL(fileURLWithPath: "\(RecordDirName.first)/3.mp4"), size: 1),
            File(url: URL(fileURLWithPath: "\(RecordDirName.first)/images/1.jpg"), size: 1),
            File(url: URL(fileURLWithPath: "\(RecordDirName.first)/images/2.jpg"), size: 1),
            File(url: URL(fileURLWithPath: "\(RecordDirName.first)/images/3.jpg"), size: 1),
        ],
        URL(fileURLWithPath: RecordDirName.second, isDirectory: true): [
            File(url: URL(fileURLWithPath: "\(RecordDirName.second)/gps.bin"), size: 15),
            File(url: URL(fileURLWithPath: "\(RecordDirName.second)/videos.json"), size: 1),
            File(url: URL(fileURLWithPath: "\(RecordDirName.second)/1.mp4"), size: 1),
            File(url: URL(fileURLWithPath: "\(RecordDirName.second)/2.mp4"), size: 1),
            File(url: URL(fileURLWithPath: "\(RecordDirName.second)/3.mp4"), size: 1),
            File(url: URL(fileURLWithPath: "\(RecordDirName.second)/images/1.jpg"), size: 1),
            File(url: URL(fileURLWithPath: "\(RecordDirName.second)/images/2.jpg"), size: 1),
            File(url: URL(fileURLWithPath: "\(RecordDirName.second)/images/3.jpg"), size: 1),
        ],
        URL(fileURLWithPath: RecordDirName.empty, isDirectory: true): [
            File(url: URL(fileURLWithPath: "\(RecordDirName.empty)/.synced"), size: 0),
        ],
    ]

    static let defaultWaitingTime: TimeInterval = 10.0

    // MARK: - Properties

    var networkClient: MockNetworkClient!
    var dataSource: MockRecordDataSource!
    var archiver: MockArchiver!
    var recordSynchronizer: RecordSynchronizer!
    var fileManager: MockFileManager!
    var deviceInfo: DeviceInfoProvider!

    // MARK: - Setup and teardown

    override func setUp() {
        super.setUp()

        networkClient = MockNetworkClient()
        dataSource = MockRecordDataSource()
        archiver = MockArchiver()
        fileManager = MockFileManager()
        deviceInfo = DeviceInfoProvider()

        recordSynchronizer = RecordSynchronizer(RecordSynchronizer.Dependencies(
            networkClient: networkClient,
            dataSource: dataSource,
            deviceInfo: deviceInfo,
            archiver: archiver,
            fileManager: fileManager
        ))
        recordSynchronizer.delegate = self

        fileManager.data = data.values.flatMap { $0 }
        dataSource.recordDirectories = data.keys.map { $0 }
    }

    override func tearDown() {
        networkClient = nil
        dataSource = nil
        archiver = nil
        fileManager = nil
        deviceInfo = nil
        recordSynchronizer = nil

        super.tearDown()
    }

    // MARK: - Tests

    func testPositiveScenario() {
        // Given state from setUp()

        // When
        recordSynchronizer.sync()

        // Then
        wait(for: [TestExpectation.positiveScenario], timeout: RecordSynchronizerTests.defaultWaitingTime)
    }

    func testSyncMethodCleansEmptyRecordsDirWhenSynchedIsPerformed() {
        // Given state from setUp()

        // When
        recordSynchronizer.sync()

        // Then
        wait(for: [TestExpectation.emptyRecordDirIsRemoved], timeout: RecordSynchronizerTests.defaultWaitingTime)
    }

    func testSyncMethodCleansOldestRecordsIfQuotaIsExceeded() {
        // Given state from setUp()

        let data = [
            URL(fileURLWithPath: RecordDirName.first, isDirectory: true): [
                File(url: URL(fileURLWithPath: "\(RecordDirName.first)/gps.bin"), size: 20),
                File(url: URL(fileURLWithPath: "\(RecordDirName.first)/videos.json"), size: 3),
                File(url: URL(fileURLWithPath: "\(RecordDirName.first)/1.mp4"), size: 100 * .mByte),
                File(url: URL(fileURLWithPath: "\(RecordDirName.first)/2.mp4"), size: 100 * .mByte),
                File(url: URL(fileURLWithPath: "\(RecordDirName.first)/3.mp4"), size: 1),
                File(url: URL(fileURLWithPath: "\(RecordDirName.first)/images/1.jpg"), size: 1),
                File(url: URL(fileURLWithPath: "\(RecordDirName.first)/images/2.jpg"), size: 1),
                File(url: URL(fileURLWithPath: "\(RecordDirName.first)/images/3.jpg"), size: 1),
            ],
            URL(fileURLWithPath: RecordDirName.second, isDirectory: true): [
                File(url: URL(fileURLWithPath: "\(RecordDirName.second)/gps.bin"), size: 15),
                File(url: URL(fileURLWithPath: "\(RecordDirName.second)/videos.json"), size: 1),
                File(url: URL(fileURLWithPath: "\(RecordDirName.second)/1.mp4"), size: 100 * .mByte),
                File(url: URL(fileURLWithPath: "\(RecordDirName.second)/2.mp4"), size: 100 * .mByte),
                File(url: URL(fileURLWithPath: "\(RecordDirName.second)/3.mp4"), size: 1),
                File(url: URL(fileURLWithPath: "\(RecordDirName.second)/images/1.jpg"), size: 1),
                File(url: URL(fileURLWithPath: "\(RecordDirName.second)/images/2.jpg"), size: 1),
                File(url: URL(fileURLWithPath: "\(RecordDirName.second)/images/3.jpg"), size: 1),
            ],
            URL(fileURLWithPath: RecordDirName.empty, isDirectory: true): [
                File(url: URL(fileURLWithPath: "\(RecordDirName.empty)/.synced"), size: 0),
            ],
        ]

        fileManager.data = data.values.flatMap { $0 }
        dataSource.recordDirectories = data.keys.map { $0 }

        // When
        recordSynchronizer.sync()

        // Then
        wait(for: [TestExpectation.oldestRecordDirIsRemoved], timeout: RecordSynchronizerTests.defaultWaitingTime)
    }

    func testSyncMethodDoesNotPerfromCleanIfQuotaIsNotExceeded() {
        // TODO: implement
    }
}

extension RecordSynchronizerTests: SyncDelegate {
    func syncStarted() {}

    func syncStopped() {
        if dataSource.removedFiles.contains(URL(fileURLWithPath: RecordDirName.empty, isDirectory: true)) {
            TestExpectation.emptyRecordDirIsRemoved.fulfill()
        }

        if dataSource.removedFiles.contains(URL(fileURLWithPath: RecordDirName.first, isDirectory: true)) {
            TestExpectation.oldestRecordDirIsRemoved.fulfill()
        }

//        let archives = [
//            URL(fileURLWithPath: "/1/telemetry.zip"),
//            URL(fileURLWithPath: "/2/telemetry.zip"),
//            URL(fileURLWithPath: "/1/images.zip"),
//            URL(fileURLWithPath: "/2/images.zip"),
//        ]
//
//        XCTAssert(archiver.archives.count == archives.count, "Archiver should create \(archives.count) archives")
//
//        archives.forEach { archive in
//            XCTAssertNotNil(archiver.archives[archive], "Archiver should create archive with right path")
//            let uploadDir = networkClient.uploaded[archive]
//            let dir = "\(archive.pathComponents[1])_en_US_\(deviceInfo.id)_\(deviceInfo.platformName)"
//            XCTAssert(uploadDir == dir, "\(archive) should be uploaded to \(dir). Actual upload dir: \(uploadDir ?? "none")")
//            XCTAssert(dataSource.removedFiles.contains(archive), "\(archive) should be removed after upload")
//        }
//
//        XCTAssert(dataSource.removedFiles.contains(URL(fileURLWithPath: "/1/gps.bin")), "Bin file should be removed after archivation")
//        XCTAssert(dataSource.removedFiles.contains(URL(fileURLWithPath: "/1/videos.json")), "Json file should be removed after archivation")
//
//        XCTAssert(fileManager.fileExists(atPath: "/1/.synced"), "Telemetry from first dir should be marked as synced")
//        XCTAssert(fileManager.fileExists(atPath: "/2/.synced"), "Telemetry from second dir should be marked as synced")
//
//        let files = [
//            URL(fileURLWithPath: "/1/1.mp4"),
//            URL(fileURLWithPath: "/1/2.mp4"),
//            URL(fileURLWithPath: "/1/3.mp4"),
//            URL(fileURLWithPath: "/2/1.mp4"),
//            URL(fileURLWithPath: "/2/2.mp4"),
//            URL(fileURLWithPath: "/2/3.mp4"),
//        ]
//
//        files.forEach { file in
//            let uploadDir = networkClient.uploaded[file]
//            let dir = "\(file.pathComponents[1])_en_US_\(deviceInfo.id)_\(deviceInfo.platformName)"
//            XCTAssert(uploadDir == dir, "\(file) should be uploaded to \(dir). Actual upload dir: \(uploadDir ?? "none")")
//            XCTAssert(dataSource.removedFiles.contains(file), "\(file) should be removed after upload")
//        }
//
//        TestExpectation.positiveScenario.fulfill()
    }
}
