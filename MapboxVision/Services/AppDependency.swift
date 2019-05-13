//
//  AppDependency.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 3/13/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionNative

private let visionSessionInterval: TimeInterval = 5 * 60
private let visionVideoSettings: VideoSettings = .lowQuality

protocol VisionDependency {
    var synchronizer: Synchronizable { get }
    var recorder: SessionRecorder { get }
    var native: VisionManagerNative { get }
    var locationManager: LocationManager { get }
    var motionManager: MotionManager { get }
    var deviceInfo: DeviceInfoProvidable { get }
}

final class AppDependency: VisionDependency {
    private(set) var synchronizer: Synchronizable
    private(set) var native: VisionManagerNative
    private(set) var recorder: SessionRecorder
    private(set) var locationManager: LocationManager
    private(set) var motionManager: MotionManager
    private(set) var deviceInfo: DeviceInfoProvidable
    private let eventsManager = EventsManager()
    private let platform: Platform
    
    init(operationMode: OperationMode) {
        
        guard let reachability = Reachability() else {
            fatalError("Reachability failed to initialize")
        }
        
        self.deviceInfo = DeviceInfoProvider()
        
        let dataSource = SyncRecordDataSource()
        let recordArchiver = RecordArchiver()
        let recordSyncDependencies = RecordSynchronizer.Dependencies(
            networkClient: eventsManager,
            dataSource: dataSource,
            deviceInfo: deviceInfo,
            archiver: recordArchiver,
            fileManager: FileManager.default
        )
        let recordSynchronizer = RecordSynchronizer(recordSyncDependencies)

        let syncDependencies = ManagedSynchronizer.Dependencies(
            base: recordSynchronizer,
            reachability: reachability
        )
        self.synchronizer = ManagedSynchronizer(dependencies: syncDependencies)
        
        let recorder = RecordCoordinator()
        
        self.platform = Platform(dependencies: Platform.Dependencies(
            recordCoordinator: recorder,
            eventsManager: eventsManager
        ))
        
        self.native = VisionManagerNative.create(withPlatform: platform)
        
        self.recorder = SessionRecorder(dependencies: SessionRecorder.Dependencies(
            recorder: recorder,
            sessionManager: SessionManager(),
            videoSettings: visionVideoSettings,
            sessionInterval: visionSessionInterval,
            getSeconds: native.getSeconds,
            startSavingSession: native.startSavingSession,
            stopSavingSession: native.stopSavingSession
        ))
        
        self.locationManager = LocationManager()
        self.motionManager = MotionManager(with: platform.getMotionReferenceFrame())
    }
}
