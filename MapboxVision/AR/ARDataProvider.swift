//
// Created by Alexander Pristavko on 8/21/18.
// Copyright (c) 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionCore

/**
    Interface for AR relative data provider. It used for communication between MapboxVision and MapboxVisionAR frameworks.
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
