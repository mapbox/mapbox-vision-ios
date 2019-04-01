//
//  Constants
//  VisionExample
//
//  Copyright © 2019 Mapbox. All rights reserved.
//

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
    )
]
