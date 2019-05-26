import CoreMedia

extension CMSampleBuffer {
    var pixelBuffer: CVPixelBuffer? {
        return CMSampleBufferGetImageBuffer(self)
    }
}
