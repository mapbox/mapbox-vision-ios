//
//  MapboxVisionTests.swift
//  MapboxVisionTests
//
//  Created by Maksim on 9/28/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import XCTest

@testable import MapboxVision

class RecordSynchronizerTests: XCTestCase, SyncDelegate {
    
    var networkClient: MockNetworkClient!
    var dataSource: MockRecordDataSource!
    var archiver: MockArchiver!
    var recordSynchronizer: RecordSynchronizer!
    var fileManager: MockFileManager!
    
    let positiveScenarioExpectation = XCTestExpectation(description: "Positive scenario")

    override func setUp() {
        networkClient = MockNetworkClient()
        dataSource = MockRecordDataSource()
        archiver = MockArchiver()
        fileManager = MockFileManager()
        recordSynchronizer = RecordSynchronizer(RecordSynchronizer.Dependencies(
            networkClient: networkClient,
            dataSource: dataSource,
            deviceId: "DEVICE_ID",
            devicePlatformName: "iOS",
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
            ],
            URL(fileURLWithPath: "/2", isDirectory: true) : [
                File(url: URL(fileURLWithPath: "/2/gps.bin"), size: 15),
                File(url: URL(fileURLWithPath: "/2/videos.json"), size: 1),
                File(url: URL(fileURLWithPath: "/2/1.mp4"), size: 1),
                File(url: URL(fileURLWithPath: "/2/2.mp4"), size: 1),
                File(url: URL(fileURLWithPath: "/2/3.mp4"), size: 1),
            ],
            URL(fileURLWithPath: "/3", isDirectory: true) : [
                File(url: URL(fileURLWithPath: "/3/.synced"), size: 0)
            ]
        ]
        
        fileManager.data = data
        dataSource.recordDirectories = data.keys.map { $0 }
        
        recordSynchronizer.sync()
        wait(for: [positiveScenarioExpectation], timeout: 10.0)
    }
    
    func syncStarted() {
        XCTAssert(dataSource.removedFiles.contains(URL(fileURLWithPath: "/3", isDirectory: true)), "Empty dir should be removed")
    }
    
    func syncStopped() {
        
        XCTAssert(archiver.archives.count == 2, "Archiver should create 2 archives");
        
        let firstArchive = URL(fileURLWithPath: "/1/telemetry.zip")
        let secondArchive = URL(fileURLWithPath: "/2/telemetry.zip")
        
        XCTAssertNotNil(archiver.archives[firstArchive], "Archiver should create archive with right path");
        XCTAssertNotNil(archiver.archives[secondArchive], "Archiver should create archive with right path");
        
        XCTAssert(dataSource.removedFiles.contains(URL(fileURLWithPath: "/1/gps.bin")), "Bin file should be removed after archivation")
        XCTAssert(dataSource.removedFiles.contains(URL(fileURLWithPath: "/1/videos.json")), "Json file should be removed after archivation")
        
        XCTAssert(networkClient.uploaded[firstArchive] == "1_en_US_DEVICE_ID_iOS", "First archive should be uploaded to right dir")
        XCTAssert(networkClient.uploaded[secondArchive] == "2_en_US_DEVICE_ID_iOS", "Second archive should be uploaded to right dir")
        
        XCTAssert(dataSource.removedFiles.contains(firstArchive), "First archive should be removed after upload")
        XCTAssert(dataSource.removedFiles.contains(secondArchive), "Second archive should be removed after upload")
        
        XCTAssert(fileManager.fileExists(atPath: "/1/.synced"), "Telemetry from first dir should be marked as synced")
        XCTAssert(fileManager.fileExists(atPath: "/2/.synced"), "Telemetry from second dir should be marked as synced")
        
        let video1_1 = URL(fileURLWithPath: "/1/1.mp4")
        let video1_2 = URL(fileURLWithPath: "/1/2.mp4")
        let video1_3 = URL(fileURLWithPath: "/1/3.mp4")
        let video2_1 = URL(fileURLWithPath: "/2/1.mp4")
        let video2_2 = URL(fileURLWithPath: "/2/2.mp4")
        let video2_3 = URL(fileURLWithPath: "/2/3.mp4")
        
        XCTAssert(networkClient.uploaded[video1_1] == "1_en_US_DEVICE_ID_iOS", "Video from first dir should be uploaded to right dir")
        XCTAssert(networkClient.uploaded[video1_2] == "1_en_US_DEVICE_ID_iOS", "Video from first dir should be uploaded to right dir")
        XCTAssert(networkClient.uploaded[video1_3] == "1_en_US_DEVICE_ID_iOS", "Video from first dir should be uploaded to right dir")
        XCTAssert(networkClient.uploaded[video2_1] == "2_en_US_DEVICE_ID_iOS", "Video from second dir should be uploaded to right dir")
        XCTAssert(networkClient.uploaded[video2_2] == "2_en_US_DEVICE_ID_iOS", "Video from second dir should be uploaded to right dir")
        XCTAssert(networkClient.uploaded[video2_3] == "2_en_US_DEVICE_ID_iOS", "Video from second dir should be uploaded to right dir")
        
        XCTAssert(dataSource.removedFiles.contains(video1_1), "Video should be removed after upload")
        XCTAssert(dataSource.removedFiles.contains(video1_2), "Video should be removed after upload")
        XCTAssert(dataSource.removedFiles.contains(video1_3), "Video should be removed after upload")
        XCTAssert(dataSource.removedFiles.contains(video2_1), "Video should be removed after upload")
        XCTAssert(dataSource.removedFiles.contains(video2_2), "Video should be removed after upload")
        XCTAssert(dataSource.removedFiles.contains(video2_3), "Video should be removed after upload")
        
        positiveScenarioExpectation.fulfill()
    }
}
