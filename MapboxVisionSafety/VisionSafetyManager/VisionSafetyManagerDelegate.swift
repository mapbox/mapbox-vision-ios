import Foundation

/**
 Interface that user’s custom object should conform to in order to receive events from `VisionSafetyManager`.
 Delegate methods will not be called until `Camera.isCalibrated` value becomes `true` due to highly imprecise results.
 Delegate methods are called one by one followed by `visionManagerDidCompleteUpdate` call on a delegate of `VisionManager`.

 NOTE: All delegate methods are called on a background thread.
 */
public protocol VisionSafetyManagerDelegate: AnyObject {
    /**
     Tells the delegate that current road restrictions were updated.
     `Camera` needs to be calibrated for the event to be triggered.
     */
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateRoadRestrictions: RoadRestrictions)

    /**
     Tells the delegate that new probable collisions were detected.
     `Camera` needs to be calibrated for the event to be triggered.
     */
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateCollisions: [CollisionObject])

    /**
     Tells the delegate that impact is detected
     */
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didDetectImpact: ImpactDetection)

    /**
     Tells the delegate that the current forward car is updated
     Use the `CollisionObject.timeToImpact` property to evaluate if you're tailgating the forward car.
     `Camera` needs to be calibrated for the event to be triggered.
     */
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateForwardCar forwardCar: CollisionObject?)

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didDetectHardAcceleration: HardAccelerationDetection)

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didDetectHardBraking: HardBrakingDetection)

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didDetectHardCornering: HardCorneringDetection)

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didDetectLaneChanging: LaneChangingDetection)

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didDetectStopSignRunning: StopSignRunningDetection)
}

public extension VisionSafetyManagerDelegate {
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateRoadRestrictions: RoadRestrictions) {}

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateCollisions: [CollisionObject]) {}

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didDetectImpact: ImpactDetection) {}

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateForwardCar forwardCar: CollisionObject?) {}

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didDetectHardAcceleration: HardAccelerationDetection) {}

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didDetectHardBraking: HardBrakingDetection) {}

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didDetectHardCornering: HardCorneringDetection) {}

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didDetectLaneChange: LaneChangeDetection) {}

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didDetectRunStopSign: RunStopSignDetection) {}
}
