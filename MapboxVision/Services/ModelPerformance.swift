//
//  ModelPerformance.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 9/4/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import UIKit

/**
 Enumeration which determines whether SDK should adapt its performance to environmental changes (acceleration/deceleration, standing time) or stay fixed.
*/
public enum ModelPerformanceMode {
    /**
        Fixed.
    */
    case fixed
    /**
        Dynamic. It depends on speed. Variable from ModelPerformanceRate.low (0 km/h) to VisionManager's performance property (90 km/h).
    */
    case dynamic
}

/**
 Enumeration which determines performance rate of the specific model. These are high-level settings that translates into adjustment of FPS for ML model inference.
*/
public enum ModelPerformanceRate {
    /**
        Identifies that output of particular model is not required.
    */
    case off
    /**
        Low.
    */
    case low
    /**
        Medium.
    */
    case medium
    /**
        High.
    */
    case high
}

/**
 Enumeration representing configuration for ML models
*/

public enum ModelPerformanceConfig: Equatable {
    public static func == (lhs: ModelPerformanceConfig, rhs: ModelPerformanceConfig) -> Bool {
        switch (lhs, rhs) {
        case let (.merged(rhsPerformance), .merged(lhsPerformance)):
            return rhsPerformance == lhsPerformance
        case let (.separate(lhsSegmentationPerformance, lhsDetectionPerformance),
                  .separate(rhsSegmentationPerformance, rhsDetectionPerformance)):
            return
                lhsSegmentationPerformance == rhsSegmentationPerformance &&
                lhsDetectionPerformance == rhsDetectionPerformance
        default:
            return false
        }
    }
    
    /**
        Segmentation and detection are produced by one merged model.
        Works more efficiently in a workflow requiring comparable performance for detection and segmentation.
     */
    case merged(performance: ModelPerformance)
    /**
        Segmentation and detection are produced by separate models.
        May perform better when segmentation and detection are required to produce output with different frequencies.
     */
    case separate(segmentationPerformance: ModelPerformance, detectionPerformance: ModelPerformance)
}

/**
 Structure representing performance setting for tasks related to specific ML model. It’s defined as a combination of mode and rate.
*/
public struct ModelPerformance: Equatable {
    
    /**
        Performance Mode.
    */
    public let mode: ModelPerformanceMode
    /**
        Performance Rate
    */
    public let rate: ModelPerformanceRate

    /**
        Initializer.
    */
    public init(mode: ModelPerformanceMode, rate: ModelPerformanceRate) {
        self.mode = mode
        self.rate = rate
    }
}

enum ModelType {
    case segmentation, detection
}

enum CoreModelPerformance {
    case fixed(fps: Float)
    case dynamic(minFps: Float, maxFps: Float)
}

struct ModelPerformanceResolver {
    private struct PerformanceEntry {
        let off: Float
        let low: Float
        let high: Float
        
        func fps(for rate: ModelPerformanceRate) -> Float {
            switch rate {
            case .off:
                return off
            case .low:
                return low
            case .medium:
                return (low + high) / 2
            case .high:
                return high
            }
        }
    }
    
    private static let isTopDevice = UIDevice.current.isTopDevice
    
    private static let segmentationHighEnd   = PerformanceEntry(off: 1, low: 2, high: 7)
    private static let detectionHighEnd      = PerformanceEntry(off: 3, low: 4, high: 12)
    
    private static let segmentationLowEnd    = PerformanceEntry(off: 1, low: 2, high: 5)
    private static let detectionLowEnd       = PerformanceEntry(off: 3, low: 4, high: 11)
    
    private static func performanceEntry(for model: ModelType) -> PerformanceEntry {
        switch model {
        case .segmentation:
            return isTopDevice ? segmentationHighEnd : segmentationLowEnd
        case .detection:
            return isTopDevice ? detectionHighEnd : detectionLowEnd
        }
    }
    
    static func coreModelPerformance(for model: ModelType, with performance: ModelPerformance) -> CoreModelPerformance {
        let entry = performanceEntry(for: model)
        
        switch performance.mode {
        case .fixed:
            return .fixed(fps: entry.fps(for: performance.rate))
        case .dynamic:
            let minFps = entry.fps(for: .low)
            let maxFps = entry.fps(for: performance.rate)
            return .dynamic(minFps: minFps, maxFps: maxFps)
        }
    }
}
