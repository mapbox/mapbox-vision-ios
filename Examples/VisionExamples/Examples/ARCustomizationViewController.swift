import MapboxVisionAR
import UIKit

/**
 * "AR Customization" tutorial demonstrates how to customize vision AR visuals which are AR lane and AR fence.
 * The tutorial is based on "ARNavigation" example which shows how to get the route, convert it to vision format,
 * create vision manager anв set up the vision AR session with the route.
 */
class ARCustomizationViewController: ARNavigationViewController {
    // To customize AR visuals you will need VisionARViewController and VisionARManager objects
    // Let's arrenge customization in closures which takes both of these obejcts as parameters,
    // so the different visual style can be expressed by one closure.
    // Let's take a look at different AR visual styles:
    let customizationExamples: [(VisionARManager, VisionARViewController) -> Void] = [
        // To change the visible lane length you should call VisionARManager's method `set(laneLength:)`
        { visionARManager, visionARViewController in
            // Set the desired lane length in meters.
            visionARManager.set(laneLength: 20)
        },
        // Let's set a few more different lane length values to see the difference
        { visionARManager, visionARViewController in
            visionARManager.set(laneLength: 30)
        }, { visionARManager, visionARViewController in
            visionARManager.set(laneLength: 40)
        },
        // To customize lane appearence you need to use LaneVisualParams structure.
        // Its constructor inits all the fields with the values which is used
        // by VisionARViewController by default
        { visionARManager, visionARViewController in
            // Create an instance of `LaneVisualParams`
            var laneVisualParams = LaneVisualParams()
            // Set the color
            laneVisualParams.color = UIColor.red
            /// Also you can adjust lane width in meters
            laneVisualParams.width = 0.5
            /// And chevron length in meters
            laneVisualParams.arrowLength = 1
            // After `laneVisualParams` is configured you need to set it to the view controller
            visionARViewController.set(laneVisualParams: laneVisualParams)
        },
        // Let's customize lane with different visual params to see the difference
        { visionARManager, visionARViewController in
            var laneVisualParams = LaneVisualParams()
            laneVisualParams.color = UIColor.white
            laneVisualParams.width = 1
            laneVisualParams.arrowLength = 6
            visionARViewController.set(laneVisualParams: laneVisualParams)
        }, { visionARManager, visionARViewController in
            var laneVisualParams = LaneVisualParams()
            laneVisualParams.color = UIColor.blue
            laneVisualParams.width = 4
            laneVisualParams.arrowLength = 2.5
            visionARViewController.set(laneVisualParams: laneVisualParams)
        }, { visionARManager, visionARViewController in
            // Set lane visual params to defaults. Setting lane visual params doesn't affect lane length
            visionARViewController.set(laneVisualParams: LaneVisualParams())
        },
        // To customize fence visibility distance you should call method `set(fenceVisibilityDistance:)`
        // You may want to use lower value of fence visibility distance for higher performance because it requires less
        // computations
        { visionARManager, visionARViewController in
            // First of all you need to enable fence rendering
            visionARViewController.isFenceVisible = true
            // Also you may want to stop showing AR lane
            visionARViewController.isLaneVisible = false
            // Set the desired fence visibility distance in meters.
            visionARManager.set(fenceVisibilityDistance: 100)
        },
        // Let's set a few more different values to see the difference
        { visionARManager, visionARViewController in
            visionARManager.set(laneLength: 150)
        }, { visionARManager, visionARViewController in
            visionARManager.set(laneLength: 250)
        },
       // To customize fence appearence you need to use FenceVisualParams structure.
       // Its constructor inits all the fields with the values which is used
       // by VisionARViewController by default
        { visionARManager, visionARViewController in
            // Create an instance of `FenceVisualParams`
            let fenceVisualParams = FenceVisualParams()
            // Set the color of the fence
            fenceVisualParams.color = UIColor.green
            // Set the height of the fence in meters
            fenceVisualParams.height = 3
            // Set the vertical offset of the fence above the road surface in meters
            fenceVisualParams.verticalOffset = 0
            // Set the horizontal offset of the fence from the center of the road in meters
            fenceVisualParams.horizontalOffset = 5
            // Set the number of arrows in the fence
            fenceVisualParams.sectionsCount = 4
            // After `fenceVisualParams` is configured you need to set it to the view controller
            visionARViewController.set(fenceVisualParams: fenceVisualParams)
        },
        // Let's customize fence with different visual params to see the difference
        { visionARManager, visionARViewController in
            let fenceVisualParams = FenceVisualParams()
            fenceVisualParams.color = UIColor.red
            fenceVisualParams.height = 2
            fenceVisualParams.verticalOffset = 1.5
            fenceVisualParams.horizontalOffset = 2
            fenceVisualParams.sectionsCount = 5
            visionARViewController.set(fenceVisualParams: fenceVisualParams)
        }, { visionARManager, visionARViewController in
            let fenceVisualParams = FenceVisualParams()
            fenceVisualParams.color = UIColor.brown
            fenceVisualParams.height = 1.5
            fenceVisualParams.verticalOffset = 0.5
            fenceVisualParams.horizontalOffset = 3
            fenceVisualParams.sectionsCount = 6
            // Let's show lane as well
            visionARViewController.isLaneVisible = true
            visionARViewController.set(fenceVisualParams: fenceVisualParams)
        }, { visionARManager, visionARViewController in
            let fenceVisualParams = FenceVisualParams()
            fenceVisualParams.color = UIColor.yellow
            fenceVisualParams.height = 4
            fenceVisualParams.verticalOffset = 0
            fenceVisualParams.horizontalOffset = 5
            fenceVisualParams.sectionsCount = 3
            visionARViewController.set(fenceVisualParams: fenceVisualParams)
        }, { visionARManager, visionARViewController in
            // Set fence visual params to defaults. Setting fence visual params doesn't visibility distance
            visionARViewController.set(fenceVisualParams: FenceVisualParams())
        }
    ]

    var customizationIndex: Int = 0

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // In order to show all the possible customizations, which is not possible at one time, let's use timer
        // to switch styles every second to see the difference between different settings.
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {[weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.customizationExamples[self.customizationIndex](self.visionARManager, self.visionARViewController)
            self.customizationIndex += 1
            self.customizationIndex %= self.customizationExamples.count
        }
        timer.fire()
    }
}
