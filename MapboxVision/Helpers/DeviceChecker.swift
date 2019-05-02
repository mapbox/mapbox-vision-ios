//
//  Created by Alexander Pristavko on 8/10/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import UIKit
import MapboxVisionNative

private let iPhoneName = "iPhone"
private let iPhoneMinModel = 10 // meaning iPhone 8/8Plus/X

extension UIDevice {
    var isTopDevice: Bool {
        var prefix: String = ""
        var minModel: Int = 0
        
        var modelID = self.modelID
        
        if modelID.hasPrefix(iPhoneName) {
            prefix = iPhoneName
            minModel = iPhoneMinModel
        }
        
        guard !prefix.isEmpty, minModel > 0 else { return false }
        
        modelID.removeFirst(prefix.count)
        
        if let majorVersion = modelID.split(separator: ",").first, let majorNumber = Int(majorVersion) {
            return majorNumber == minModel
        }
        
        return false
    }
}
