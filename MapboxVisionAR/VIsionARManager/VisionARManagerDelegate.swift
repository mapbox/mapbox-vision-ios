import Foundation

/**
 Interface that user’s custom object should conform to in order to receive events from `VisionARManager`.
 Delegate methods are called one by one followed by `visionManagerDidCompleteUpdate` call on a delegate of `VisionManager`.

 - NOTE: All delegate methods are called on a background thread.
 */
public protocol VisionARManagerDelegate: AnyObject {
    /**
     Tells the delegate that AR camera was updated.
     */
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARCamera camera: ARCamera)

    /**
     Tells the delegate that AR lane was updated.
     */
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARLane lane: ARLane?)

    /**
     Tells the delegate that AR mask was updated.
     */
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARMask: Image)

    /**
     Tells the delegate that AR lane cutoff was updated.
     */
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARLaneCutoff: Float)
}

public extension VisionARManagerDelegate {
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARCamera camera: ARCamera) {}

    func visionARManager(_ visionARManager: VisionARManager, didUpdateARLane lane: ARLane?) {}

    func visionARManager(_ visionARManager: VisionARManager, didUpdateARMask: Image) {}

    func visionARManager(_ visionARManager: VisionARManager, didUpdateARLaneCutoff: Float) {}
}
