//
//  ManeuverLocation.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 9/4/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import VisionCore

/**
    Location of route maneuver
*/

public struct ManeuverLocation: Equatable {
    /**
        Position in world coordinates
    */
    public let origin: CGPoint
}
