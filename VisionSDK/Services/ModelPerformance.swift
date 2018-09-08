//
//  ModelPerformance.swift
//  VisionSDK
//
//  Created by Alexander Pristavko on 9/4/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import UIKit

public enum ModelPerformanceMode {
    case fixed, dynamic
}

public enum ModelPerformanceRate {
    case low, medium, high
}

public struct ModelPerformance {
    public let mode: ModelPerformanceMode
    public let rate: ModelPerformanceRate

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
        let low: Float
        let high: Float
        
        func fps(for rate: ModelPerformanceRate) -> Float {
            switch rate {
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
    
    private static let segmentationHighEnd   = PerformanceEntry(low: 2, high: 7)
    private static let detectionHighEnd      = PerformanceEntry(low: 4, high: 12)
    
    private static let segmentationLowEnd    = PerformanceEntry(low: 2, high: 5)
    private static let detectionLowEnd       = PerformanceEntry(low: 4, high: 11)
    
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
