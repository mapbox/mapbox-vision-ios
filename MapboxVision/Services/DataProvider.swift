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
        let frameSize = CGPoint(x: settings.width, y: settings.height)
        let currentTimeMS = DispatchTime.now().uptimeMilliseconds - startTime + dependencies.startTime
        telemetryPlayer.setCurrentTime(currentTimeMS)
        telemetryPlayer.updateData(withFrameSize: frameSize, srcSize: frameSize)
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
