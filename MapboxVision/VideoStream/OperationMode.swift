//
//  OperationMode.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 9/25/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

/**
 Operation mode determines whether vision manager works normally or focuses just on gathering data.
 */
public enum OperationMode {
    /// Utilizes machine learning models and uploads gathered telemetry
    case normal
    /// Turns off machine learning inference, saves source videos, stores telemetry locally
    case dataRecording
    
    var usesSegmentation: Bool {
        switch self {
        case .normal:
            return true
        case .dataRecording:
            return false
        }
    }
    
    var usesDetection: Bool {
        switch self {
        case .normal:
            return true
        case .dataRecording:
            return false
        }
    }
    
    var savesSourceVideo: Bool {
        switch self {
        case .normal:
            return false
        case .dataRecording:
            return true
        }
    }
    
    var isSyncEnabled: Bool {
        switch self {
        case .normal:
            return true
        case .dataRecording:
            return false
        }
    }
    
    var sessionInterval: TimeInterval {
        switch self {
        case .normal:
            return 5 * 60
        case .dataRecording:
            return 30 * 60
        }
    }
}
