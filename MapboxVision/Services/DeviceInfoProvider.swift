//
//  DeviceInfoProvider.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 3/13/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import UIKit

protocol DeviceInfoProvidable {
    var id: String { get }
    var platformName: String { get }
    
    func reset()
}

final class DeviceInfoProvider: DeviceInfoProvidable {
    
    lazy var id: String = DeviceInfoProvider.generateID()
    let platformName: String = UIDevice.current.systemName
    
    private var interruptionStartTime: Date?
    
    func reset() {
        id = DeviceInfoProvider.generateID()
    }
    
    private static func generateID() -> String {
        return NSUUID().uuidString
    }
}
