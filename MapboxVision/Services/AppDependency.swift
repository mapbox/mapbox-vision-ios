//
//  AppDependency.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 3/13/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionNative

protocol VisionDependency {
    var recordSynchronizer: RecordSynchronizer { get }
    var reachability: Reachability { get }
    var recorder: RecordCoordinator { get }
    var native: VisionManagerNative { get }
    var locationManager: LocationManager { get }
    var motionManager: MotionManager { get }
    var deviceInfo: DeviceInfoProvidable { get }
}

final class AppDependency: VisionDependency {
    private(set) var reachability: Reachability
    private(set) var recordSynchronizer: RecordSynchronizer
    private(set) var native: VisionManagerNative
    private(set) var recorder: RecordCoordinator
    private(set) var locationManager: LocationManager
    private(set) var motionManager: MotionManager
    private(set) var deviceInfo: DeviceInfoProvidable
    private let eventsManager = EventsManager()
    private let platform: Platform
    
    init(operationMode: OperationMode) {
        
        guard let reachability = Reachability() else {
            fatalError("Reachability failed to initialize")
        }
        self.reachability = reachability
        
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
        
        self.recorder = RecordCoordinator()
        
        self.platform = Platform(dependencies: Platform.Dependencies(
            recordCoordinator: recorder,
            eventsManager: eventsManager
        ))
        
        self.native = VisionManagerNative.create(withPlatform: platform)
        
        self.locationManager = LocationManager()
        self.motionManager = MotionManager(with: platform.getMotionReferenceFrame())
    }
}
