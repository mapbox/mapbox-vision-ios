import MapboxVisionAR
import UIKit

/**
 * "AR Customization" tutorial demonstrates how to customize vision AR visuals - AR lane and AR fence.
 * The tutorial is based on "ARNavigation" example which shows how to get the route and set up Vision AR session.
 */
class ARCustomizationViewController: ARNavigationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Adjust AR rendering quality
        visionARViewController.set(arQuality: 0.8)

        // Make sure lane is visible
        visionARViewController.isLaneVisible = true
        // Set lane length in meters
        visionARManager.set(laneLength: 40)

        // Create an instance of `LaneVisualParams`
        let laneVisualParams = LaneVisualParams()
        // Set lane color
        laneVisualParams.color = UIColor.red
        // Set lane width in meters
        laneVisualParams.width = 1
        // Set the length of chevrons in meters
        laneVisualParams.arrowLength = 2.5

        // Once `laneVisualParams` is configured, set it to the view controller
        visionARViewController.set(laneVisualParams: laneVisualParams)

        // Enable fence rendering
        visionARViewController.isFenceVisible = true
        // Set fence length in meters
        visionARManager.set(fenceVisibilityDistance: 200)

        // Create an instance of `FenceVisualParams`
        let fenceVisualParams = FenceVisualParams()
        // Set fence color
        fenceVisualParams.color = UIColor.yellow
        // Set fence height in meters
        fenceVisualParams.height = 2
        // Set fence vertical offset above the road surface in meters
        fenceVisualParams.verticalOffset = 1
        // Set fence horizontal offset from the camera in meters
        fenceVisualParams.horizontalOffset = 3
        // Set the number of arrows in the fence
        fenceVisualParams.sectionsCount = 3

        // Once `fenceVisualParams` is configured, set it to the view controller
        visionARViewController.set(fenceVisualParams: fenceVisualParams)
    }

    private func restoreDefaultValues() {
        // Set the new lane visual params without changes
        visionARViewController.set(laneVisualParams: LaneVisualParams())
        // Set the new fence visual params without changes
        visionARViewController.set(fenceVisualParams: FenceVisualParams())
        // Disable fence rendering
        visionARViewController.isFenceVisible = false
    }
}
