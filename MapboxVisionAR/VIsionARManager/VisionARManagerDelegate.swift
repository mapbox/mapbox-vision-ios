//
//  VisionARManagerDelegate.swift
//  MapboxVisionAR
//
//  Created by Maksim on 3/15/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation

public protocol VisionARManagerDelegate: class {
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARCamera camera: ARCamera)
    
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARLane lane: ARLane?)
}

public extension VisionARManagerDelegate {
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARCamera camera: ARCamera) {}
    
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARLane lane: ARLane?) {}
}
