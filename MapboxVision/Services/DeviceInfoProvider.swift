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
}

final class DeviceInfoProvider: DeviceInfoProvidable {
    
    let id: String = {
        UIDevice.current.identifierForVendor?.uuidString ?? NSUUID().uuidString
    }()
    
    let platformName: String = UIDevice.current.systemName
}
