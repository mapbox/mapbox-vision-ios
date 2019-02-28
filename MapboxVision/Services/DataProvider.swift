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
    func currentTime() -> UInt
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
    }
    
    func update() {
        let settings = dependencies.recordingPath.settings
        let frameSize = Point2I(x: settings.width, y: settings.height)
        telemetryPlayer.setCurrentTime(currentTime())
        telemetryPlayer.updateData(dependencies.core, frameSize: frameSize, srcSize: frameSize)
        telemetryPlayer.moveNextFrame()
    }
    
    func stop() {}

    func currentTime() -> UInt {
        return DispatchTime.now().uptimeMilliseconds - startTime + dependencies.startTime
    }
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

    func currentTime() -> UInt {
        return UInt(dependencies.core.getSeconds())
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

    func currentTime() -> UInt {
        return 0
    }
}

private extension DispatchTime {
    var uptimeMilliseconds: UInt {
        return UInt(DispatchTime.now().uptimeNanoseconds / 1_000_000)
    }
}
