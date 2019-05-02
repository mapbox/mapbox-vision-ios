//
//  Created by Alexander Pristavko on 1/9/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import UIKit

final class ImageRecorder {
    func record(image: UIImage, to path: String) {
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            assertionFailure("ERROR: Unable to obtain data representation of UIImage")
            return
        }
        do {
            try data.write(to: URL(fileURLWithPath: path))
        } catch {
            assertionFailure("ERROR: Unable to save image to \(path). Error: \(error)")
        }
    }
}
