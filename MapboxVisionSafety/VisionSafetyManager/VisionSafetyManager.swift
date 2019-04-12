//
//  VisionSafetyManager.swift
//  MapboxVisionSafety
//
//  Created by Maksim on 3/15/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation
import MapboxVision
import MapboxVisionSafetyNative

public final class VisionSafetyManager {
    
    private var native: VisionSafetyManagerNative?
    private var delegate: VisionSafetyManagerDelegate?
    
    public static func create(visionManager: VisionManager, delegate: VisionSafetyManagerDelegate? = nil) -> VisionSafetyManager {
        let manager = VisionSafetyManager()
        manager.native = VisionSafetyManagerNative.create(visionManager: visionManager.native, delegate: manager)
        manager.delegate = delegate
        return manager
    }
    
    public func destroy() {
        assert(native != nil, "VisionSafetyManager has already been destroyed")
        native?.destroy()
        native = nil
        delegate = nil
    }
    
    public func setTimeToCollisionWithVehicle(warningTime: Float, criticalTime: Float) {
        native?.setTimeToCollisionWithVehicle(warningTime, criticalTime: criticalTime)
    }
    
    public func setCollisionWithVehicleMinSpeed(minSpeed: Float) {
        native?.setCollisionMinSpeed(minSpeed)
    }
}

extension VisionSafetyManager: VisionSafetyDelegate {
    public func onRoadRestrictionsUpdated(_ roadRestrictions: RoadRestrictions) {
        delegate?.visionSafetyManager(self, didUpdateRoadRestrictions: roadRestrictions)
    }
    
    public func onCollisionsUpdated(_ collisions: [CollisionObject]) {
        delegate?.visionSafetyManager(self, didUpdateCollisions: collisions)
    }
}
