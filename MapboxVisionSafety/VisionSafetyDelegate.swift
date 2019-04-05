//
//  VisionSafetyDelegate.swift
//  MapboxVisionSafety
//
//  Created by Maksim on 3/15/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation

public protocol VisionSafetyManagerDelegate: class {
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateRoadRestrictions: RoadRestrictions)
    
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateCollisions: [CollisionObject])
}
    
public extension VisionSafetyManagerDelegate {
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateRoadRestrictions: RoadRestrictions) {}
    
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager, didUpdateCollisions: [CollisionObject]) {}
}
