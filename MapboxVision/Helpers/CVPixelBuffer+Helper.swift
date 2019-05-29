import CoreMedia
import CoreVideo
import Foundation

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
