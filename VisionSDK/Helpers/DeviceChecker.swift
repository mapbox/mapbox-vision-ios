//
//  DeviceChecker.swift
//  VisionSDK
//
//  Created by Alexander Pristavko on 8/10/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import UIKit

private let iPhoneName = "iPhone"
private let iPhoneMinModel = 10 // meaning iPhone 8/8Plus/X

extension UIDevice {
    var isTopDevice: Bool {
        var prefix: String = ""
        var minModel: Int = 0
        
        var modelId = self.modelId
        
        if modelId.hasPrefix(iPhoneName) {
            prefix = iPhoneName
            minModel = iPhoneMinModel
        }
        
        guard !prefix.isEmpty, minModel > 0 else { return false }
        
        modelId.removeFirst(prefix.count)
        
        if let majorVersion = modelId.split(separator: ",").first, let majorNumber = Int(majorVersion) {
            return majorNumber == minModel
        }
        
        return false
    }
    
    private var modelId: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
