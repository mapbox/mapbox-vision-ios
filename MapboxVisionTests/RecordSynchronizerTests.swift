import XCTest

@testable import MapboxVision

class RecordSynchronizerTests: XCTestCase {
    typealias File = MockFileManager.File

    var networkClient: MockNetworkClient!
    var dataSource: MockRecordDataSource!
    var archiver: MockArchiver!
    var recordSynchronizer: RecordSynchronizer!
    var fileManager: MockFileManager!
    var deviceInfo: DeviceInfoProvider!
    var syncDelegate: ClosureSyncDelegate!
    
    private let data = [
        URL(fileURLWithPath: "/1", isDirectory: true): [
            File(url: URL(fileURLWithPath: "/1/gps.bin"), size: 20),
            File(url: URL(fileURLWithPath: "/1/videos.json"), size: 3),
            File(url: URL(fileURLWithPath: "/1/1.mp4"), size: 1),
            File(url: URL(fileURLWithPath: "/1/2.mp4"), size: 1),
            File(url: URL(fileURLWithPath: "/1/3.mp4"), size: 1),
            File(url: URL(fileURLWithPath: "/1/images/1.jpg"), size: 1),
            File(url: URL(fileURLWithPath: "/1/images/2.jpg"), size: 1),
            File(url: URL(fileURLWithPath: "/1/images/3.jpg"), size: 1),
        ],
        URL(fileURLWithPath: "/2", isDirectory: true): [
            File(url: URL(fileURLWithPath: "/2/gps.bin"), size: 15),
            File(url: URL(fileURLWithPath: "/2/videos.json"), size: 1),
            File(url: URL(fileURLWithPath: "/2/1.mp4"), size: 1),
            File(url: URL(fileURLWithPath: "/2/2.mp4"), size: 1),
            File(url: URL(fileURLWithPath: "/2/3.mp4"), size: 1),
            File(url: URL(fileURLWithPath: "/2/images/1.jpg"), size: 1),
            File(url: URL(fileURLWithPath: "/2/images/2.jpg"), size: 1),
            File(url: URL(fileURLWithPath: "/2/images/3.jpg"), size: 1),
        ],
        URL(fileURLWithPath: "/3", isDirectory: true): [
            File(url: URL(fileURLWithPath: "/3/.synced"), size: 0),
        ],
    ]
    
    override func setUp() {
        super.setUp()
        
        networkClient = MockNetworkClient()
        dataSource = MockRecordDataSource()
        archiver = MockArchiver()
        fileManager = MockFileManager()
        deviceInfo = DeviceInfoProvider()
        syncDelegate = ClosureSyncDelegate()
        recordSynchronizer = RecordSynchronizer(RecordSynchronizer.Dependencies(
                networkClient: networkClient,
                deviceInfo: deviceInfo,
                archiver: archiver,
                fileManager: fileManager
        ))
        recordSynchronizer.set(dataSource: dataSource)
        recordSynchronizer.delegate = syncDelegate
    }
    
    func testPositiveScenario() {
        // Given
        fileManager.data = data.values.flatMap { $0 }
        dataSource.recordDirectories = data.keys.map { $0 }
        
        let expectation = XCTestExpectation(description: "Positive scenario")
        
        syncDelegate.onSyncStopped = {
            self.positiveScenarioOnSyncStopped(expectation)
        }
        
        // When
        recordSynchronizer.sync()
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testStoppingSyncBeforeAllDataIsUploaded() {
        // Given
        fileManager.data = data.values.flatMap { $0 }
        dataSource.recordDirectories = data.keys.map { $0 }
        
        let expectation = XCTestExpectation(description: "Cancellation")
        
        syncDelegate.onSyncStopped = {
            let uploads: Set = [
                URL(fileURLWithPath: "/1/telemetry.zip"),
                URL(fileURLWithPath: "/2/telemetry.zip"),
            ]
            
            XCTAssert(Set(self.networkClient.uploaded.keys) == uploads, "Synchronizer should be able to upload only telemetry.")
            expectation.fulfill()
        }
        
        // When
        recordSynchronizer.sync()
        DispatchQueue.main.async {
            self.recordSynchronizer.stopSync()
        }
        
        // Then
        wait(for: [expectation], timeout: 1)
    }
}

extension RecordSynchronizerTests {
    func positiveScenarioOnSyncStopped(_ expectation: XCTestExpectation) {
        XCTAssertFalse(fileManager.urls.contains(URL(fileURLWithPath: "/3", isDirectory: true)), "Empty dir should be removed")

        let archives = [
            URL(fileURLWithPath: "/1/telemetry.zip"),
            URL(fileURLWithPath: "/2/telemetry.zip"),
            URL(fileURLWithPath: "/1/images.zip"),
            URL(fileURLWithPath: "/2/images.zip"),
        ]

        XCTAssert(archiver.archives.count == archives.count, "Archiver should create \(archives.count) archives")

        archives.forEach { archive in
            XCTAssertNotNil(archiver.archives[archive], "Archiver should create archive with right path")
            let uploadDir = networkClient.uploaded[archive]
            let dir = "\(archive.pathComponents[1])_en_US_\(deviceInfo.id)_\(deviceInfo.platformName)"
            XCTAssert(uploadDir == dir, "\(archive) should be uploaded to \(dir). Actual upload dir: \(uploadDir ?? "none")")
            XCTAssertFalse(fileManager.urls.contains(archive), "\(archive) should be removed after upload")
        }

        XCTAssertFalse(fileManager.urls.contains(URL(fileURLWithPath: "/1/gps.bin")), "Bin file should be removed after archivation")
        XCTAssertFalse(fileManager.urls.contains(URL(fileURLWithPath: "/1/videos.json")), "Json file should be removed after archivation")

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

        files.forEach { file in
            let uploadDir = networkClient.uploaded[file]
            let dir = "\(file.pathComponents[1])_en_US_\(deviceInfo.id)_\(deviceInfo.platformName)"
            XCTAssert(uploadDir == dir, "\(file) should be uploaded to \(dir). Actual upload dir: \(uploadDir ?? "none")")
            XCTAssertFalse(fileManager.urls.contains(file), "\(file) should be removed after upload")
        }
        
        expectation.fulfill()
    }
}
