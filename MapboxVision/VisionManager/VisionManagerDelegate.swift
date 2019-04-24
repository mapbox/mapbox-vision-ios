//
//  VisionManagerDelegate.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 3/5/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionNative

/**
    Interface that user’s custom object should conform to in order to receive events from `VisionManager`.
    Delegate methods are called one by one followed by `visionManagerDidCompleteUpdate` call, which denotes the end of the iteration.
 
    - NOTE: All delegate methods are called on a background thread.
*/
public protocol VisionManagerDelegate: class {
    
    /**
        Tells the delegate that authorization status was updated.
        `VisionManager` may not emit events unless it has successfully authorized.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateAuthorizationStatus authorizationStatus: AuthorizationStatus) -> Void
    
    /**
        Tells the delegate that segmentation mask was updated.
        Requires at least low performance for segmentation.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateFrameSegmentation frameSegmentation: FrameSegmentation) -> Void
    
    /**
        Tells the delegate that detections were updated.
        Requires at least low performance for detection.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateFrameDetections frameDetections: FrameDetections) -> Void
    
    /**
        Tells the delegate that classified signs were updated.
        Requires at least low performance for detection.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateFrameSignClassifications frameSignClassifications: FrameSignClassifications) -> Void
    
    /**
        Tells the delegate that road description was updated.
        Road description parameters reach maximum accuracy when `Camera` is calibrated.
        Requires at least low performance for segmentation.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateRoadDescription roadDescription: RoadDescription) -> Void
    
    /**
        Tells the delegate that world description was updated.
        World description parameters reach maximum accuracy when `Camera` is calibrated.
        Requires at least low performance for detection.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateWorldDescription worldDescription: WorldDescription) -> Void
    
    /**
        Tells the delegate that vehicle state was updated.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateVehicleState vehicleState: VehicleState) -> Void
    
    /**
        Tells the delegate that country which is used in the VisionSDK changed.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateCountry country: Country) -> Void
    
    /**
        Tells the delegate that camera state was updated.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateCamera camera: Camera) -> Void
    
    /**
        This method is called after the whole update iteration is completed. This means that all the data which came from delegate methods is in sync.
        This method is an appropriate place to work with different values emitted from `VisionManager`.
        
        - NOTE: Performance of this function is critical since `VisionManager` blocks until the method execution is finished.
    */
    func visionManagerDidCompleteUpdate(_ visionManager: VisionManager) -> Void
}

public extension VisionManagerDelegate {
    func visionManager(_ visionManager: VisionManager, didUpdateAuthorizationStatus authorizationStatus: AuthorizationStatus) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateFrameSegmentation frameSegmentation: FrameSegmentation) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateFrameDetections frameDetections: FrameDetections) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateFrameSignClassifications frameSignClassifications: FrameSignClassifications) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateRoadDescription roadDescription: RoadDescription) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateWorldDescription worldDescription: WorldDescription) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateVehicleState vehicleState: VehicleState) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateCamera camera: Camera) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateCountry country: Country) -> Void {}
    
    func visionManagerDidCompleteUpdate(_ visionManager: VisionManager) -> Void {}
}
