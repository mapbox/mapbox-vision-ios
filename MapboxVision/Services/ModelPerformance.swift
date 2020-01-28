import Foundation
import UIKit

/**
 Enumeration which determines whether SDK should adapt its performance to environmental changes (acceleration/deceleration, standing time) or stay fixed.
 */
public enum ModelPerformanceMode {
    /**
     Fixed mode.
     */
    case fixed

    /**
     Dynamic mode. Performance depends on speed.
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
    /// :nodoc:
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
     Performance Rate.
     */
    public let rate: ModelPerformanceRate

    /**
     Creates an instance of model performance with mode and rate.
     */
    public init(mode: ModelPerformanceMode, rate: ModelPerformanceRate) {
        self.mode = mode
        self.rate = rate
    }
}

enum CoreModelPerformance {
    case fixed(fps: Float)
    case dynamic(minFps: Float, maxFps: Float)
}

enum ModelPerformanceResolver {
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

    private static let isHighPerformance = UIDevice.current.isHighPerformance

    private static let    segmentationHighEnd = PerformanceEntry(off: 1, low: 2, high: 7)
    private static let       detectionHighEnd = PerformanceEntry(off: 3, low: 4, high: 12)
    private static let mergedSegDetectHighEnd = PerformanceEntry(off: 3, low: 4, high: 12)

    private static let     segmentationLowEnd = PerformanceEntry(off: 1, low: 2, high: 5)
    private static let        detectionLowEnd = PerformanceEntry(off: 3, low: 4, high: 11)
    private static let  mergedSegDetectLowEnd = PerformanceEntry(off: 3, low: 4, high: 11)

    private static func performanceEntry(for model: MLModelType) -> PerformanceEntry {
        switch model {
        case .segmentation:
            return isHighPerformance ? segmentationHighEnd : segmentationLowEnd
        case .detection:
            return isHighPerformance ? detectionHighEnd : detectionLowEnd
        case .mergedSegDetect:
            return isHighPerformance ? mergedSegDetectHighEnd : mergedSegDetectLowEnd
        }
    }

    static func coreModelPerformance(for model: MLModelType, with performance: ModelPerformance) -> CoreModelPerformance {
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
