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

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateImpactDetection: ImpactDetection)
}

public extension VisionSafetyManagerDelegate {
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateRoadRestrictions: RoadRestrictions) {}

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateCollisions: [CollisionObject]) {}

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateImpactDetection: ImpactDetection) {}
}
