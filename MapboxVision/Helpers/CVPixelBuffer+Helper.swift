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
