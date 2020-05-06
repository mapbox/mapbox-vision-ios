import CoreMedia
import CoreVideo
import Foundation

extension CMSampleBuffer {
    var pixelBuffer: CVPixelBuffer? {
        CMSampleBufferGetImageBuffer(self)
    }
}

extension CVPixelBuffer {
    var width: Int {
        CVPixelBufferGetWidth(self)
    }

    var height: Int {
        CVPixelBufferGetHeight(self)
    }
}
