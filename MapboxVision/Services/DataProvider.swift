//
//  DataProvider.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 5/4/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionCore

protocol DataProvider: AnyObject {
    func start()
    func update()
    func stop()
}

final class RecordedDataProvider: DataProvider {
    struct Dependencies {
        let recordingPath: RecordingPath
        let startTime: UInt
    }
    
    let dependencies: Dependencies
    let telemetryPlayer: TelemetryPlayer
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        self.telemetryPlayer = TelemetryPlayer()
        telemetryPlayer.read(fromFolder: dependencies.recordingPath.recordingPath)
    }
    
    private var startTime = DispatchTime.now().uptimeMilliseconds
    
    func start() {
        startTime = DispatchTime.now().uptimeMilliseconds
        telemetryPlayer.scrollData(dependencies.startTime)
    }
    
    func update() {
        let settings = dependencies.recordingPath.settings
        let frameSize = CGSize(width: settings.width, height: settings.height)
        let currentTimeMS = DispatchTime.now().uptimeMilliseconds - startTime + dependencies.startTime
        telemetryPlayer.setCurrentTime(currentTimeMS)
        telemetryPlayer.updateData(withFrameSize: frameSize, srcSize: frameSize)
    }
    
    func stop() {}
}

final class RealtimeDataProvider: DataProvider {
    struct Dependencies {
        let native: VisionManagerNative
        let motionManager: MotionManager
        let locationManager: LocationManager
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        dependencies.motionManager.handler = dependencies.native.setDeviceMotion
        dependencies.locationManager.locationHandler = dependencies.native.setGPS
        dependencies.locationManager.headingHandler = dependencies.native.setHeading
    }
    
    func start() {
        dependencies.locationManager.start()
        dependencies.motionManager.start(updateInterval: Constants.motionUpdateInterval)
    }

    func update() {}
    
    func stop() {
        dependencies.locationManager.stop()
        dependencies.motionManager.stop()
    }
}

final class EmptyDataProvider: DataProvider {
    func start() {}
    
    func update() {}
    
    func stop() {}
}

private extension DispatchTime {
    var uptimeMilliseconds: UInt {
        return UInt(DispatchTime.now().uptimeNanoseconds / 1_000_000)
    }
}
