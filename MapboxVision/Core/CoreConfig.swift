//
//  CoreConfig.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 5/18/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import VisionCore

extension CoreConfig {
    static var empty: CoreConfig {
        let config = CoreConfig()
    
        config.useSegmentation = false
        config.useDetection = false
        config.useClassification = false
        config.useTracking = false
        config.useDebugOverlay = false
        config.drawSegMaskInDebug = false
        config.solveCameraWorldTransform = false
        config.drawCurLaneInDebug = false
        config.drawMarkingLanesInDebug = false
        config.drawRouteInDebug = false
        config.useCarDistanceMeasure = false
        config.useTrajectoryEstimator = false
        config.useMapMatching = false
        config.saveTelemetry = false
        config.useDetectionMapping = false
        config.useMergeMLModelLaunch = false
        
        return config
    }
    
    static var basic: CoreConfig {
        let config = empty
        
        config.solveCameraWorldTransform = true
        config.saveTelemetry = true
        
        config.useSegmentation = true
        config.useDetection = true
        config.useClassification = true
        config.useMapMatching = true
        
        config.setSegmentationFixedFPS(1)
        config.setDetectionFixedFPS(4)
    
        config.useDetectionMapping = true
        config.useMergeMLModelLaunch = true
        
        return config
    }
    
    static var distanceToCar: CoreConfig {
        let config = segmentationFirst
        
        config.useCarDistanceMeasure = true
        
        return config
    }
    
    static var segmentationFirst: CoreConfig {
        let config = basic

        config.setSegmentationFixedFPS(UIDevice.current.isTopDevice ? 7 : 5)
        
        return config
    }
    
    static var detectionFirst: CoreConfig {
        let config = basic
        
        config.setDetectionFixedFPS(UIDevice.current.isTopDevice ? 12 : 11)
        
        return config
    }
}
