import Foundation
import UIKit

typealias NamedController = (
    name: String,
    description: String,
    controllerType: UIViewController.Type
)

let listOfExamples: [NamedController] = [
    (
        name: "External video source",
        description: "Demonstrates how to provide custom implementation of video source to VisionManager.",
        controllerType: ExternalCameraViewController.self
    ),
    (
        name: "Over speeding detection",
        description: "Demonstrates how to combine VisionSafety events with position.",
        controllerType: OverSpeedingViewController.self
    ),
    (
        name: "AR navigation",
        description: "Demonstrates how to setup VisionAR and display default AR route.",
        controllerType: ARNavigationViewController.self
    ),
    (
        name: "POI drawing",
        description: """
            Demonstrates how to draw a point of interest on the screen knowing its geographical coordinates
            and using coordinate transformation functions.
        """,
        controllerType: POIDrawingViewController.self
    )
]
