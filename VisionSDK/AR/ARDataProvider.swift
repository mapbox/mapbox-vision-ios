//
// Created by Alexander Pristavko on 8/21/18.
// Copyright (c) 2018 Mapbox. All rights reserved.
//

import Foundation
import VisionCore

/**
    Interface for AR relative data provider. It used for commutication between VisionSDK and VisionAR frameworks.
*/

public protocol ARDataProvider {
    /**
        Device parameters
    */
    func getCameraParams() -> ARCameraParameters
    /**
        AR Qubic spline of route
    */
    func getARRouteData() -> ARRouteData
}
