import Foundation
import MapboxVision
import MapboxVisionFleetNative
import MapboxVisionSafety

public final class VisionFleetManager {

    public weak var delegate: VisionFleetManagerDelegate?

    public static func create(visionManager: VisionManagerProtocol, visionSafetyManager: VisionSafetyManager) -> VisionFleetManager {
        let manager = VisionFleetManager()
        return manager
    }

    public func destroy() {

    }
}
