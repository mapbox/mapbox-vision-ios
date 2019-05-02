//
//  Created by Alexander Pristavko on 2019-01-17.
//  Copyright (c) 2019 Mapbox. All rights reserved.
//

import Foundation
import CoreVideo
import CoreMedia

extension CMSampleBuffer {
    var pixelBuffer: CVPixelBuffer? {
        return CMSampleBufferGetImageBuffer(self)
    }
}

extension CVPixelBuffer {
    var width: Int {
        return CVPixelBufferGetWidth(self)
    }
    
    var height: Int {
        return CVPixelBufferGetHeight(self)
    }
}
