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
        let core: Core
        let recordingPath: RecordingPath
        let startTime: UInt
    }
    
    let dependencies: Dependencies
    let telemetryPlayer: TelemetryPlayer
    var time: UInt
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        self.telemetryPlayer = TelemetryPlayer()
        telemetryPlayer.read(fromFolder: dependencies.recordingPath.recordingPath)
        telemetryPlayer.scrollData(Int(dependencies.startTime))
        time = dependencies.startTime
    }
    
    private var startTime = DispatchTime.now().uptimeMilliseconds
    
    func start() {
        startTime = DispatchTime.now().uptimeMilliseconds
    }
    
    private func getDelta() -> UInt {
        let currentTime = DispatchTime.now().uptimeMilliseconds
        let dt = DispatchTime.now().uptimeMilliseconds - startTime
        startTime = currentTime
        return dt
    }
    
    func update() {
        let settings = dependencies.recordingPath.settings
        let frameSize = Point2I(x: settings.width, y: settings.height)

        time += getDelta()
        
        telemetryPlayer.setCurrentTime(time)
        telemetryPlayer.updateData(dependencies.core, frameSize: frameSize, srcSize: frameSize)
    }
    
    func stop() {}
}

final class RealtimeDataProvider: DataProvider {
    struct Dependencies {
        let core: Core
        let motionManager: MotionManager
        let metaInfoManager: MetaInfoManager
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        dependencies.motionManager.handler = dependencies.core.setDeviceMotion
    }
    
    func start() {
        dependencies.metaInfoManager.addObserver(self)
        dependencies.metaInfoManager.start()
        dependencies.motionManager.start(updateInterval: Constants.motionUpdateInterval)
    }

    func update() {}
    
    func stop() {
        dependencies.metaInfoManager.removeObserver(self)
        dependencies.metaInfoManager.stop()
        dependencies.motionManager.stop()
    }
}

extension RealtimeDataProvider: MetaInfoObserver {
    func location(_ location: CLLocation) {
        dependencies.core.setGPSData(location)
    }
    
    func heading(_ heading: CLHeading) {
        dependencies.core.setHeadingData(heading)
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
