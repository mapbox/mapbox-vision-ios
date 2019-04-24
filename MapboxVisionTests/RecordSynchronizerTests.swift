import XCTest

@testable import MapboxVision

class RecordSynchronizerTests: XCTestCase, SyncDelegate {

    var networkClient: MockNetworkClient!
    var dataSource: MockRecordDataSource!
    var archiver: MockArchiver!
    var recordSynchronizer: RecordSynchronizer!
    var fileManager: MockFileManager!
    var deviceInfo: DeviceInfoProvider!

    let positiveScenarioExpectation = XCTestExpectation(description: "Positive scenario")

    override func setUp() {
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
    }

    override func tearDown() {
        networkClient = nil
        dataSource = nil
        archiver = nil
        recordSynchronizer = nil
        fileManager = nil
    }

    func testPositiveScenario() {

        typealias File = MockFileManager.File

        let data = [
            URL(fileURLWithPath: "/1", isDirectory: true) : [
                File(url: URL(fileURLWithPath: "/1/gps.bin"), size: 20),
                File(url: URL(fileURLWithPath: "/1/videos.json"), size: 3),
                File(url: URL(fileURLWithPath: "/1/1.mp4"), size: 1),
                File(url: URL(fileURLWithPath: "/1/2.mp4"), size: 1),
                File(url: URL(fileURLWithPath: "/1/3.mp4"), size: 1),
                File(url: URL(fileURLWithPath: "/1/images/1.jpg"), size: 1),
                File(url: URL(fileURLWithPath: "/1/images/2.jpg"), size: 1),
                File(url: URL(fileURLWithPath: "/1/images/3.jpg"), size: 1),
            ],
            URL(fileURLWithPath: "/2", isDirectory: true) : [
                File(url: URL(fileURLWithPath: "/2/gps.bin"), size: 15),
                File(url: URL(fileURLWithPath: "/2/videos.json"), size: 1),
                File(url: URL(fileURLWithPath: "/2/1.mp4"), size: 1),
                File(url: URL(fileURLWithPath: "/2/2.mp4"), size: 1),
                File(url: URL(fileURLWithPath: "/2/3.mp4"), size: 1),
                File(url: URL(fileURLWithPath: "/2/images/1.jpg"), size: 1),
                File(url: URL(fileURLWithPath: "/2/images/2.jpg"), size: 1),
                File(url: URL(fileURLWithPath: "/2/images/3.jpg"), size: 1),
            ],
            URL(fileURLWithPath: "/3", isDirectory: true) : [
                File(url: URL(fileURLWithPath: "/3/.synced"), size: 0)
            ]
        ]

        fileManager.data = data.values.flatMap { $0 }
        dataSource.recordDirectories = data.keys.map { $0 }

        recordSynchronizer.sync()
        wait(for: [positiveScenarioExpectation], timeout: 10.0)
    }

    func syncStarted() {
        XCTAssert(dataSource.removedFiles.contains(URL(fileURLWithPath: "/3", isDirectory: true)), "Empty dir should be removed")
    }

    func syncStopped() {

        let archives = [
            URL(fileURLWithPath: "/1/telemetry.zip"),
            URL(fileURLWithPath: "/2/telemetry.zip"),
            URL(fileURLWithPath: "/1/images.zip"),
            URL(fileURLWithPath: "/2/images.zip"),
        ]

        XCTAssert(archiver.archives.count == archives.count, "Archiver should create \(archives.count) archives");

        archives.forEach { (archive) in
            XCTAssertNotNil(archiver.archives[archive], "Archiver should create archive with right path")
            let uploadDir = networkClient.uploaded[archive]
            let dir = "\(archive.pathComponents[1])_en_US_\(deviceInfo.id)_\(deviceInfo.platformName)"
            XCTAssert(uploadDir == dir, "\(archive) should be uploaded to \(dir). Actual upload dir: \(uploadDir ?? "none")")
            XCTAssert(dataSource.removedFiles.contains(archive), "\(archive) should be removed after upload")
        }

        XCTAssert(dataSource.removedFiles.contains(URL(fileURLWithPath: "/1/gps.bin")), "Bin file should be removed after archivation")
        XCTAssert(dataSource.removedFiles.contains(URL(fileURLWithPath: "/1/videos.json")), "Json file should be removed after archivation")

        XCTAssert(fileManager.fileExists(atPath: "/1/.synced"), "Telemetry from first dir should be marked as synced")
        XCTAssert(fileManager.fileExists(atPath: "/2/.synced"), "Telemetry from second dir should be marked as synced")

        let files = [
            URL(fileURLWithPath: "/1/1.mp4"),
            URL(fileURLWithPath: "/1/2.mp4"),
            URL(fileURLWithPath: "/1/3.mp4"),
            URL(fileURLWithPath: "/2/1.mp4"),
            URL(fileURLWithPath: "/2/2.mp4"),
            URL(fileURLWithPath: "/2/3.mp4"),
        ]

        files.forEach { (file) in
            let uploadDir = networkClient.uploaded[file]
            let dir = "\(file.pathComponents[1])_en_US_\(deviceInfo.id)_\(deviceInfo.platformName)"
            XCTAssert(uploadDir == dir, "\(file) should be uploaded to \(dir). Actual upload dir: \(uploadDir ?? "none")")
            XCTAssert(dataSource.removedFiles.contains(file), "\(file) should be removed after upload")
        }

        positiveScenarioExpectation.fulfill()
    }
}
