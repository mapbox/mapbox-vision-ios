import MapboxVisionARNative
import UIKit

/**
 Set visual parameters for AR Lane.

 - Parameters:
 - laneVisualParams: Configuration that describes visual state of AR lane.
 */
extension VisionARViewController {
    public func set(laneVisualParams: LaneVisualParams) {
        self.laneVisualParams = laneVisualParams
    }
}
