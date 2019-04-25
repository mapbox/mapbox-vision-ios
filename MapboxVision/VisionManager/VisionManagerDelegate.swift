import Foundation
import MapboxVisionNative

/**
 Interface that user’s custom object should conform to in order to receive events from `VisionManager`.
 Delegate methods are called one by one followed by `visionManagerDidCompleteUpdate` call, which denotes the end of the iteration.

 - NOTE: All delegate methods are called on a background thread.
 */
public protocol VisionManagerDelegate: AnyObject {
    /**
     Tells the delegate that authorization status was updated.
     `VisionManager` may not emit events unless it has successfully authorized.
     */
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateAuthorizationStatus authorizationStatus: AuthorizationStatus)
    
    /**
     Tells the delegate that segmentation mask was updated.
     Requires at least low performance for segmentation.
     */
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateFrameSegmentation frameSegmentation: FrameSegmentation)
    
    /**
     Tells the delegate that detections were updated.
     Requires at least low performance for detection.
     */
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateFrameDetections frameDetections: FrameDetections)
    
    /**
     Tells the delegate that classified signs were updated.
     Requires at least low performance for detection.
     */
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateFrameSignClassifications frameSignClassifications: FrameSignClassifications)
    
    /**
     Tells the delegate that road description was updated.
     Road description parameters reach maximum accuracy when `Camera` is calibrated.
     Requires at least low performance for segmentation.
     */
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateRoadDescription roadDescription: RoadDescription)
    
    /**
     Tells the delegate that world description was updated.
     World description parameters reach maximum accuracy when `Camera` is calibrated.
     Requires at least low performance for detection.
     */
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateWorldDescription worldDescription: WorldDescription)
    
    /**
     Tells the delegate that vehicle state was updated.
     */
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateVehicleState vehicleState: VehicleState)
    
    /**
     Tells the delegate that country which is used in the VisionSDK changed.
     */
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateCountry country: Country)
    
    /**
     Tells the delegate that camera state was updated.
     */
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateCamera camera: Camera)
    
    /**
     This method is called after the whole update iteration is completed. This means that all the data which came from delegate methods is in sync.
     This method is an appropriate place to work with different values emitted from `VisionManager`.
        
     - NOTE: Performance of this function is critical since `VisionManager` blocks until the method execution is finished.
     */
    func visionManagerDidCompleteUpdate(_ visionManager: VisionManagerProtocol)
}

public extension VisionManagerDelegate {
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateAuthorizationStatus authorizationStatus: AuthorizationStatus) {}
    
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateFrameSegmentation frameSegmentation: FrameSegmentation) {}
    
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateFrameDetections frameDetections: FrameDetections) {}
    
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateFrameSignClassifications frameSignClassifications: FrameSignClassifications) {}
    
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateRoadDescription roadDescription: RoadDescription) {}
    
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateWorldDescription worldDescription: WorldDescription) {}
    
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateVehicleState vehicleState: VehicleState) {}
    
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateCamera camera: Camera) {}
    
    func visionManager(_ visionManager: VisionManagerProtocol, didUpdateCountry country: Country) {}
    
    func visionManagerDidCompleteUpdate(_ visionManager: VisionManagerProtocol) {}
}
