import Foundation
import UIKit

/**
 Enumeration which determines whether SDK should adapt its performance to environmental changes (acceleration/deceleration, standing time) or stay fixed.
 */
public enum ModelPerformanceMode: Comparable {
    /// :nodoc:
    public static func < (lhs: ModelPerformanceMode, rhs: ModelPerformanceMode) -> Bool {
        if lhs == rhs { return false }
        // We condider `dynamic` to be less important than `fixed` when encountering both.
        // That's because `dynamic` mode may cause a `low` performance rate, while `fixed` one tries to keed a set value.
        return lhs == .dynamic
    }

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
public enum ModelPerformanceRate: Comparable, CaseIterable {
    /// :nodoc:
    public static func < (lhs: ModelPerformanceRate, rhs: ModelPerformanceRate) -> Bool {
        let rates = ModelPerformanceRate.allCases
        guard let lhsIndex = rates.firstIndex(of: lhs), let rhsIndex = rates.firstIndex(of: rhs) else {
            fatalError("Rates array is not complete")
        }
        return lhsIndex < rhsIndex
    }

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
 Structure representing performance setting for tasks related to specific ML model. It’s defined as a combination of mode and rate.
 */
public struct ModelPerformance: Comparable {
    /// :nodoc:
    public static func < (lhs: ModelPerformance, rhs: ModelPerformance) -> Bool {
        if lhs.mode == rhs.mode {
            return lhs.rate < rhs.rate
        }
        return lhs.mode < rhs.mode
    }

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

    private static let mergedSegDetectHighEnd = PerformanceEntry(off: 3, low: 4, high: 12)
    private static let  mergedSegDetectLowEnd = PerformanceEntry(off: 3, low: 4, high: 11)

    static func coreModelPerformance(with performance: ModelPerformance) -> CoreModelPerformance {
        let entry = isHighPerformance ? mergedSegDetectHighEnd : mergedSegDetectLowEnd

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
