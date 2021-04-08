import Foundation
import MapboxVision
import MapboxVisionSafetyNative

/**
 `VisionSafetyManager` is an entry point to the high-level framework `MapboxVisionSafety` focused on safety related tasks like collision and over speeding detection.
 Depends on `VisionManager`.
 */
public final class VisionSafetyManager {
    /// Delegate for `VisionSafetyManager`. Delegate is held as a weak reference.
    public weak var delegate: VisionSafetyManagerDelegate?

    /**
     Fabric method for creating a `VisionSafetyManager` instance.

     - Parameter visionManager: Instance of `VisionManager`.

     - Returns: Instance of `VisionSafetyManager` configured with `VisionManager` instance and delegate.
     */
    public static func create(visionManager: VisionManagerProtocol) -> VisionSafetyManager {
        let manager = VisionSafetyManager()
        manager.native = VisionSafetyManagerNative.create(visionManager: visionManager.native)
        manager.native?.delegate = manager
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
     Set minimal speed when collision system activates.

     - Parameter minSpeed: Minimal speed expressed in meters per second.
     */
    public func setCollisionWithVehicleMinSpeed(minSpeed: Float) {
        native?.setCollisionMinSpeed(minSpeed)
    }

    /**
     Set acceleration threshold for impact detector.

     - Parameter accelerationThreshold: Threshold expressed in G's
     */
    public func setImpactAccelerationThreshold(accelerationThreshold: Float) {
        native?.setImpactAccelerationThreshold(accelerationThreshold)
    }

    deinit {
        guard native != nil else { return }
        destroy()
    }

    private var native: VisionSafetyManagerNative?
}

/// :nodoc:
extension VisionSafetyManager: VisionSafetyDelegate {
    public func onRoadRestrictionsUpdated(_ roadRestrictions: RoadRestrictions) {
        delegate?.visionSafetyManager(self, didUpdateRoadRestrictions: roadRestrictions)
    }

    public func onCollisionsUpdated(_ collisions: [CollisionObject]) {
        delegate?.visionSafetyManager(self, didUpdateCollisions: collisions)
    }

    public func onImpactDetected(_ impactDetection: ImpactDetection) {
        delegate?.visionSafetyManager(self, didDetectImpact: impactDetection)
    }

    public func onForwardCarUpdated(_ forwardCar: CollisionObject?) {
        delegate?.visionSafetyManager(self, didUpdateForwardCar: forwardCar)
    }

    public func onHardAccelerationDetected(_ hardAccelerationDetection: HardAccelerationDetection) {
        delegate?.visionSafetyManager(self, didDetectHardAcceleration: hardAccelerationDetection)
    }

    public func onHardBrakingDetected(_ hardBrakingDetection: HardBrakingDetection) {
        delegate?.visionSafetyManager(self, didDetectHardBraking: hardBrakingDetection)
    }

    public func onHardCorneringDetected(_ hardCorneringDetection: HardCorneringDetection) {
        delegate?.visionSafetyManager(self, didDetectHardCornering: hardCorneringDetection)
    }

    public func onLaneChangeDetected(_ laneChangeDetection: LaneChangeDetection) {
        delegate?.visionSafetyManager(self, didDetectLaneChanging: laneChangeDetection)
    }

    public func onRunStopSignDetected(_ runStopSignDetection: RunStopSignDetection) {
        delegate?.visionSafetyManager(self, didDetectStopSignRunning: runStopSignDetection)
    }
}
