//
//  VisionARManager.swift
//  MapboxVisionAR
//
//  Created by Maksim on 3/13/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionNative
import MapboxVisionARNative
import MapboxVision

/**
    `VisionARManager` is an entry point to the high-level framework `MapboxVisionAR` focused on AR related tasks.
    Depends on `VisionManager`.
*/
public final class VisionARManager {
    
    private var native: VisionARManagerNative?
    private var delegate: VisionARManagerDelegate?
    
    /**
        Fabric method for creating a `VisionARManager` instance.
        
        - Parameter visionManager: Instance of `VisionManager`.
        - Parameter delegate: Delegate for `VisionARManager`. Delegate is held as a strong reference until `destroy` is called.
        
        - Returns: Instance of `VisionARManager` configured with `VisionManager` instance and delegate.
    */
    public static func create(visionManager: VisionManagerProtocol, delegate: VisionARManagerDelegate? = nil) -> VisionARManager {
        let manager = VisionARManager()
        manager.native = VisionARManagerNative.create(visionManager: visionManager.native, delegate: manager)
        manager.delegate = delegate
        return manager
    }

    /**
        Setup length of AR lane.

        - Parameter laneLength: Length of AR lane in meters.
    */
    func set(laneLength: Double) {
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
}

/// :nodoc:
extension VisionARManager: VisionARDelegate {
    public func onARCameraUpdated(_ camera: ARCamera) {
        delegate?.visionARManager(self, didUpdateARCamera: camera)
    }
    
    public func onARLaneUpdated(_ lane: ARLane?) {
        delegate?.visionARManager(self, didUpdateARLane: lane)
    }
}
