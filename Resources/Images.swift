import Foundation
import UIKit

private final class BundleToken {}

struct ImageAsset {
    fileprivate let name: String
    
    var image: UIImage? {
        let bundle = Bundle(for: BundleToken.self)
        let image = UIImage(named: name, in: bundle, compatibleWith: nil)
        guard let result = image else { assertionFailure("Unable to load image named \(name)."); return nil }
        return result
    }
}

enum VisionImages {
    static let logo = ImageAsset(name: "logo")
}
