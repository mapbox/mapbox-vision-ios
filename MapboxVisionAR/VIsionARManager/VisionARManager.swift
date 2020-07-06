import Foundation
import MapboxVision
import MapboxVisionARNative
import MapboxVisionNative

/**
 `VisionARManager` is an entry point to the high-level framework `MapboxVisionAR` focused on AR related tasks.
 Depends on `VisionManager`.
 */
public final class VisionARManager {
    /// Delegate for `VisionARManager`. Delegate is held as a weak reference.
    public weak var delegate: VisionARManagerDelegate?

    var native: VisionARManagerNative?

    /**
     Fabric method for creating a `VisionARManager` instance.

     - Parameter visionManager: Instance of `VisionManager`.

     - Returns: Instance of `VisionARManager` configured with `VisionManager` instance.
     */
    public static func create(visionManager: VisionManagerProtocol) -> VisionARManager {
        let manager = VisionARManager()
        manager.native = VisionARManagerNative.create(visionManager: visionManager.native)
        manager.native?.delegate = manager
        return manager
    }

    /**
     Setup length of AR lane.

     - Parameter laneLength: Length of AR lane in meters.
     */
    public func set(laneLength: Double) {
        native?.setLaneLength(laneLength)
    }

    /**
     Set AR fence visibility distance in meters.

    - Parameter fenceVisibilityDistance: fence visibility distance in meters.
    */
    public func set(fenceVisibilityDistance distance: Float) {
        native?.setFenceVisibilityDistance(distance)
    }

    /**
     Cleanup the state and resources of `VisionARManger`.
     */
    public func destroy() {
        assert(native != nil, "VisionARManager has already been destroyed")
        native?.destroy()
        native = nil
        delegate = nil
    }

    /**
     Set route to AR. Should be called on every reroute.
     */
    public func set(route: Route) {
        native?.setRoute(route)
    }

    deinit {
        guard native != nil else { return }
        destroy()
    }
}

/// :nodoc:
extension VisionARManager: VisionARDelegate {
    public func onARLaneUpdated(_ lane: ARLane?) {
        delegate?.visionARManager(self, didUpdateARLane: lane)
    }

    public func onARMaskUpdated(_ image: Image) {
        delegate?.visionARManager(self, didUpdateARMask: image)
    }

    public func onARLaneCutoffUpdated(_ cutoff: Float) {
        delegate?.visionARManager(self, didUpdateARLaneCutoff: cutoff)
    }

    public func onARFencesUpdated(_ fences: [ARFence]) {
        delegate?.visionARManager(self, didUpdateARFences: fences)
    }

    public func onRouteUpdated(_ route: Route) {
        delegate?.visionARManager(self, didUpdateRoute: route)
    }
}
