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

struct BaseDependencies {
    let native: VisionManagerBaseNative
    let synchronizer: Synchronizable
}

struct VisionDependencies {
    let native: VisionManagerNative
    let synchronizer: Synchronizable
    let recorder: SessionRecorder
    let dataProvider: DataProvider
    let deviceInfo: DeviceInfoProvidable

    static func `default`() -> VisionDependencies {
        guard let reachability = Reachability() else {
            fatalError("Reachability failed to initialize")
        }

        let eventsManager = EventsManager()
        let deviceInfo = DeviceInfoProvider()

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
        let synchronizer = ManagedSynchronizer(dependencies: syncDependencies)

        let recordCoordinator = RecordCoordinator()

        let platform = Platform(dependencies: Platform.Dependencies(
            recordCoordinator: recordCoordinator,
            eventsManager: eventsManager
        ))

        let native = VisionManagerNative.create(withPlatform: platform)

        let recorder = SessionRecorder(dependencies: SessionRecorder.Dependencies(
            recorder: recordCoordinator,
            sessionManager: SessionManager(),
            videoSettings: visionVideoSettings,
            sessionInterval: visionSessionInterval,
            getSeconds: native.getSeconds,
            startSavingSession: native.startSavingSession,
            stopSavingSession: native.stopSavingSession
        ))

        let dataProvider = RealtimeDataProvider(dependencies: RealtimeDataProvider.Dependencies(
            native: native,
            motionManager: MotionManager(with: platform.getMotionReferenceFrame()),
            locationManager: LocationManager()
        ))

        return VisionDependencies(native: native,
                                  synchronizer: synchronizer,
                                  recorder: recorder,
                                  dataProvider: dataProvider,
                                  deviceInfo: deviceInfo)
    }
}
