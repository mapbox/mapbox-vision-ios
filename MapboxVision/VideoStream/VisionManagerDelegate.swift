//
//  VisionManagerDelegate.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 3/5/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionCore

/**
 The interface that user’s custom object should conform to in order to receive events from SDK.
 */

public protocol VisionManagerDelegate: class {
    /**
     Tells the delegate that authorization status has changed. VisionManager does not emit events unless it has successfully authorized.
     */
    func visionManager(_ visionManager: VisionManager, didChangeAuthorizationStatus status: AuthorizationStatus) -> Void
    
    /**
     Tells the delegate that new segmentation is available.
     Requires at least low performance for segmentation.
     */
    func visionManager(_ visionManager: VisionManager, didUpdateFrameSegmentation frameSegmentation: FrameSegmentation) -> Void
    
    /**
     Tells the delegate that new detections are available.
     Requires at least low performance for detection.
     */
    func visionManager(_ visionManager: VisionManager, didUpdateFrameDetections frameDetections: FrameDetections) -> Void
    
    /**
     Tells the delegate that new sign classification is available.
     Requires at least low performance for detection.
     */
    func visionManager(_ visionManager: VisionManager, didUpdateFrameSigns frameSigns: FrameSigns) -> Void
    
    /**
     Tells the delegate that new processed road description is available. These are smoothed and more stable values.
     Requires at least low performance for segmentation.
     */
    func visionManager(_ visionManager: VisionManager, didUpdateRoadDescription roadDescription: RoadDescription) -> Void
    
    /**
     Tells the delegate that description of the situation on the road is updated (see [WorldDescription](https://www.mapbox.com/ios-sdk/vision/data-types/Classes/WorldDescription.html) documentation for available properties). This event won't be emitted until calibration progress reaches isCalibrated state.
     Requires at least low performance for segmentation and detection.
     */
    func visionManager(_ visionManager: VisionManager, didUpdateWorldDescription worldDescription: WorldDescription) -> Void
    
    /**
     Tells the delegate that newly estimated position is calculated.
     */
    func visionManager(_ visionManager: VisionManager, didUpdateVehicleLocation vehicleLocation: VehicleLocation) -> Void
    
    /**
     Tells the delegate about the progress of camera pose estimation (calibration).
     */
    func visionManager(_ visionManager: VisionManager, didUpdateCamera camera: Camera) -> Void
    
    /**
     Tells the delegate that the current update cycle is finished and all data is in-sync.
     */
    func visionManagerDidFinishUpdate(_ visionManager: VisionManager) -> Void
}

public extension VisionManagerDelegate {
    func visionManager(_ visionManager: VisionManager, didChangeAuthorizationStatus status: AuthorizationStatus) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateFrameSegmentation frameSegmentation: FrameSegmentation) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateFrameDetections frameDetections: FrameDetections) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateFrameSigns signs: FrameSigns) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateRoadDescription roadDescription: RoadDescription) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateWorldDescription worldDescription: WorldDescription) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateVehicleLocation vehicleLocation: VehicleLocation) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didUpdateCamera camera: Camera) -> Void {}
    
    func visionManagerDidFinishUpdate(_ visionManager: VisionManager) -> Void {}
    
    func visionManager(_ visionManager: VisionManager, didAuthorizationStatusChanged status: AuthorizationStatus) -> Void {}
}
