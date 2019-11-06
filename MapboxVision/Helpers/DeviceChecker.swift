import Foundation
import MapboxVisionNative
import UIKit

private enum DeviceModel {
    enum Name {
        static let iPhone = "iPhone"
    }

    enum MajorNumber {
        static let minIphoneVersionWithHighPerformance = 10 // "10" corresponds to 8/8 Plus/X.
        static let maxIphoneVersionWithHighPerformance = 12 // "12" corresponds to 11/11 Pro/11 Pro Max.
    }
}

extension UIDevice {
    // By default we consider next-gen iPhone as a uncapable to run models with high performance.
    // This is due to potential issues with temperature during operational mode.
    // We must do proper testing before upgrading `maxIphoneVersionWithHighPerformance`.
    var isHighPerformance: Bool {
        let modelID = self.modelID

        guard
            modelID.hasPrefix(DeviceModel.Name.iPhone),
            let currentModelMajorVersion = modelID.dropFirst(DeviceModel.Name.iPhone.count).split(separator: ",").first,
            let currentModelMajorNumber = Int(currentModelMajorVersion) else
        {
            return false
        }

        return currentModelMajorNumber >= DeviceModel.MajorNumber.minIphoneVersionWithHighPerformance &&
            currentModelMajorNumber <= DeviceModel.MajorNumber.maxIphoneVersionWithHighPerformance
    }
}
