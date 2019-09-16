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
     - Parameter delegate: Delegate for `VisionARManager`. Delegate is held as a strong reference until `destroy` is called.

     - Returns: Instance of `VisionARManager` configured with `VisionManager` instance and delegate.
     */
    @available(*, deprecated, message: "This will be removed in 0.10.0. Use method create(visionManager:) instead and set delegate as property.")
    public static func create(visionManager: VisionManagerProtocol, delegate: VisionARManagerDelegate?) -> VisionARManager {
        let arManager = create(visionManager: visionManager)
        arManager.delegate = delegate
        return arManager
    }

    /**
     Fabric method for creating a `VisionARManager` instance.

     - Parameter visionManager: Instance of `VisionManager`.

     - Returns: Instance of `VisionARManager` configured with `VisionManager` instance and delegate.
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
    public func onARCameraUpdated(_ camera: ARCamera) {
        delegate?.visionARManager(self, didUpdateARCamera: camera)
    }

    public func onARLaneUpdated(_ lane: ARLane?) {
        delegate?.visionARManager(self, didUpdateARLane: lane)
    }

    public func onARMaskUpdated(_ image: Image) {
        delegate?.visionARManager(self, didUpdateARMask: image)
    }

    public func onARLaneCutoffUpdated(_ cutoff: Float) {
        delegate?.visionARManager(self, didUpdateARLaneCutoff: cutoff)
    }
}
