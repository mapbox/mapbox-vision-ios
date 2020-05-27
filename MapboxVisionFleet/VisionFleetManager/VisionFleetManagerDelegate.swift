import Foundation
import MapboxVisionNative

public protocol VisionFleetManagerDelegate: AnyObject {
    func visionFleetManager(_ visionFleetManager: VisionFleetManager, didUpdateFleetAuthorizationStatus fleetAuthorizationStatus: AuthorizationStatus)
}

public extension VisionFleetManagerDelegate {
    func visionFleetManager(_ visionFleetManager: VisionFleetManager, didUpdateFleetAuthorizationStatus _: AuthorizationStatus) {}
}
