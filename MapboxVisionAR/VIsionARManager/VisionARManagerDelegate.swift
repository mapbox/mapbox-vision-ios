import Foundation

/**
 Interface that user’s custom object should conform to in order to receive events from `VisionARManager`.

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
     Tells the delegate that AR mask was updated. AR mask defines areas where AR should not be rendered (e.g. hood, dashboard, device mount, etc.).
     Each pixel contains a value representing confidence that AR pixel should not be rendered. Value range is [0,1], where:
        0 - pixel should be rendered,
        1 - pixel should NOT be rendered.
     */
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARMask: Image)

    /**
     Tells the delegate that AR lane cutoff was updated.
     AR lane cutoff is a relative distance where AR lane should be cut off. Range [0..1] is appropriate. Values greatest than `1` have no effect.
     */
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARLaneCutoff: Float)

    /**
     AR fences were updated
     */
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARFences arFences: [ARFence])
}

public extension VisionARManagerDelegate {
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARCamera camera: ARCamera) {}

    func visionARManager(_ visionARManager: VisionARManager, didUpdateARLane lane: ARLane?) {}

    func visionARManager(_ visionARManager: VisionARManager, didUpdateARMask: Image) {}

    func visionARManager(_ visionARManager: VisionARManager, didUpdateARLaneCutoff: Float) {}

    func visionARManager(_ visionARManager: VisionARManager, didUpdateARFences arFences: [ARFence]) {}
}
