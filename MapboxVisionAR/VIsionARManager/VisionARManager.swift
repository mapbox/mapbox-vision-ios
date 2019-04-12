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

public final class VisionARManager {
    
    private var native: VisionARManagerNative?
    private var delegate: VisionARManagerDelegate?
    
    public static func create(visionManager: VisionManager, delegate: VisionARManagerDelegate? = nil) -> VisionARManager {
        let manager = VisionARManager()
        manager.native = VisionARManagerNative.create(visionManager: visionManager.native, delegate: manager)
        manager.delegate = delegate
        return manager
    }
    
    public func destroy() {
        assert(native != nil, "VisionARManager has already been destroyed")
        native?.destroy()
        native = nil
        delegate = nil
    }
    
    public func set(route: Route) {
        native?.setRoute(route)
    }
}

extension VisionARManager: VisionARDelegate {
    public func onARCameraUpdated(_ camera: ARCamera) {
        delegate?.visionARManager(self, didUpdateARCamera: camera)
    }
    
    public func onARLaneUpdated(_ lane: ARLane?) {
        delegate?.visionARManager(self, didUpdateARLane: lane)
    }
}
