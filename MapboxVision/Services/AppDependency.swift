//
//  AppDependency.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 3/13/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionCore

protocol VisionDependency {
    var recordSynchronizer: RecordSynchronizer { get }
    var reachability: Reachability { get }
    var recorder: RecordCoordinator { get }
    var core: Core { get }
    var coreUpdater: CoreUpdater { get }
    var videoSampler: VideoSampler { get }
    var metaInfoManager: MetaInfoManager { get }
    var motionManager: MotionManager { get }
    var videoSettings: VideoSettings { get }
    var marketService: MarketService { get }
    var deviceInfo: DeviceInfoProvidable { get }
    var showcaseRecordDataSource: RecordDataSource { get }
    var broadcasting: Broadcasting { get }
}

final class AppDependency: VisionDependency {
    private(set) var reachability: Reachability
    private(set) var videoSampler: VideoSampler
    private(set) var recordSynchronizer: RecordSynchronizer
    private(set) var core: Core
    private(set) var coreUpdater: CoreUpdater
    private(set) var recorder: RecordCoordinator
    private(set) var metaInfoManager: MetaInfoManager
    private(set) var motionManager: MotionManager
    private(set) var marketService: MarketService
    private(set) var deviceInfo: DeviceInfoProvidable
    private(set) var showcaseRecordDataSource: RecordDataSource
    private(set) var broadcasting = Broadcasting(ip: "192.168.0.66", port: 5097)
    private let handlerDisposable: MarketService.Disposable
    private let eventsManager = EventsManager()
    
    let videoSettings = VideoSettings(
        width: 960,
        height: 540,
        codec: .h264,
        fileType: .mp4,
        fileExtension: "mp4",
        bitRate: 6_000_000
    )
    
    init() {
        
        guard let reachability = Reachability() else {
            fatalError("Reachability failed to initialize")
        }
        self.reachability = reachability
        
        self.videoSampler = VideoSampler(settings: videoSettings)
        
        self.deviceInfo = DeviceInfoProvider()
        
        let dataSource = SyncRecordDataSource()
        let recordArchiver = RecordArchiver()
        let syncDependencies = RecordSynchronizer.Dependencies(
            networkClient: eventsManager,
            dataSource: dataSource,
            deviceInfo: deviceInfo,
            archiver: recordArchiver,
            fileManager: FileManager.default
        )
        self.recordSynchronizer = RecordSynchronizer(syncDependencies)
        
        self.recorder = RecordCoordinator(settings: videoSettings)
        self.marketService = MarketProvider()
        
        let platform = Platform(dependencies: Platform.Dependencies(
            recordCoordinator: recorder,
            eventsManager: eventsManager
        ))
        self.core = Core(platform: platform)
        self.coreUpdater = CoreUpdater(core: core)
        
        self.metaInfoManager = MetaInfoManager()
        self.motionManager = MotionManager(with: platform.getMotionReferenceFrame())
        
        self.core.setCountry(self.marketService.currentMarket)
        self.handlerDisposable = self.marketService.subscribe(handler: core.setCountry)
        
        self.showcaseRecordDataSource = ShowcaseRecordDataSource()
    }
    
    deinit {
        self.marketService.unsubscribe(handlerDisposable)
    }
}
