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
    )
]
