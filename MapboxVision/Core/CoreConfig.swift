//
//  CoreConfig.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 5/18/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionCore

extension CoreConfig {
    static var basic: CoreConfig {
        let config = CoreConfig()
        
        config.useDetectionMapping = true
        config.useMergeMLModelLaunch = true
        
        return config
    }
}
