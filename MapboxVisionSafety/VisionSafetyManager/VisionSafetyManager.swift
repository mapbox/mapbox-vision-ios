import Foundation
import MapboxVision
import MapboxVisionSafetyNative

/**
    `VisionSafetyManager` is an entry point to the high-level framework `MapboxVisionSafety` focused on safety related tasks like collision and over speeding detection.
    Depends on `VisionManager`.
*/
public final class VisionSafetyManager {

    private var native: VisionSafetyManagerNative?
    private var delegate: VisionSafetyManagerDelegate?

    /**
        Fabric method for creating a `VisionSafetyManager` instance.
        
        - Parameter visionManager: Instance of `VisionManager`.
        - Parameter delegate: Delegate for `VisionSafetyManager`. Delegate is held as a strong reference until `destroy` is called.
        
        - Returns: Instance of `VisionSafetyManager` configured with `VisionManager` instance and delegate.
    */
    public static func create(visionManager: VisionManagerProtocol, delegate: VisionSafetyManagerDelegate? = nil) -> VisionSafetyManager {
        let manager = VisionSafetyManager()
        manager.native = VisionSafetyManagerNative.create(visionManager: visionManager.native, delegate: manager)
        manager.delegate = delegate
        return manager
    }

    /**
        Cleanup the state and resources of `VisionSafetyManger`.
    */
    public func destroy() {
        assert(native != nil, "VisionSafetyManager has already been destroyed")
        native?.destroy()
        native = nil
        delegate = nil
    }

    /**
        Set sensitivity thresholds in seconds for collision with vehicles.
        
        - Parameter warningTime: Threshold in seconds for `CollisionDangerLevel.Warning`
        - Parameter criticalTime: Threshold in seconds for `CollisionDangerLevel.Critical`
    */
    public func setTimeToCollisionWithVehicle(warningTime: Float, criticalTime: Float) {
        native?.setTimeToCollisionWithVehicle(warningTime, criticalTime: criticalTime)
    }

    /**
        Set minimal speed when collision system activates. Expressed in meters per second.
    */
    public func setCollisionWithVehicleMinSpeed(minSpeed: Float) {
        native?.setCollisionMinSpeed(minSpeed)
    }
}

/// :nodoc:
extension VisionSafetyManager: VisionSafetyDelegate {
    public func onRoadRestrictionsUpdated(_ roadRestrictions: RoadRestrictions) {
        delegate?.visionSafetyManager(self, didUpdateRoadRestrictions: roadRestrictions)
    }

    public func onCollisionsUpdated(_ collisions: [CollisionObject]) {
        delegate?.visionSafetyManager(self, didUpdateCollisions: collisions)
    }
}
