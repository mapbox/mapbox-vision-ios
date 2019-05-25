import Foundation

/**
     Interface that user’s custom object should conform to in order to receive events from `VisionSafetyManager`.
     Delegate methods are called one by one followed by `visionManagerDidCompleteUpdate` call on a delegate of `VisionManager`.
 
     NOTE: All delegate methods are called on a background thread.
*/
public protocol VisionSafetyManagerDelegate: AnyObject {

    /**
        Tells the delegate that current road restrictions were updated.
    */
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateRoadRestrictions: RoadRestrictions)

    /**
        Tells the delegate that new probable collisions were detected.
    */
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateCollisions: [CollisionObject])
}

public extension VisionSafetyManagerDelegate {
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateRoadRestrictions: RoadRestrictions) {}

    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateCollisions: [CollisionObject]) {}
}
