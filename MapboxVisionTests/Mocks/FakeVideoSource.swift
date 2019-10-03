import Foundation

@testable import MapboxVision

class FakeVideoSource: ObservableVideoSource {
    private enum Constants {
        static let fps: Int32 = 30
        static let frameDelay = 1.0 / Double(fps)
        static let frameWidth = 960
        static let frameHeight = 540
        static let bitsInByte = 8
    }

    private let processingQueue = DispatchQueue(label: "com.mapbox.RecordCoordinatorTest.VideoSource")
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now() + Constants.frameDelay, repeating: Constants.frameDelay)
        t.setEventHandler { [weak self] in
            self?.emitNewBuffer()
        }
        return t
    }()
    private var framesAlreadyWritten: Int64 = 0

    override init() {
        super.init()
    }

    func start() {
        timer.resume()
    }

    func stop() {
        timer.suspend()
    }

    @objc
    func emitNewBuffer() {
        var buffer: CMSampleBuffer?

        let pixelBuffer = makePixelBuffer()!
        let duration = CMTime(value: 1, timescale: Constants.fps)
        let pts = CMTime(value: framesAlreadyWritten, timescale: Constants.fps)
        var sampleTimingInfo = CMSampleTimingInfo(duration: duration, presentationTimeStamp: pts, decodeTimeStamp: CMTime.invalid)
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                 imageBuffer: pixelBuffer,
                                                 formatDescription: make(from: pixelBuffer)!,
                                                 sampleTiming: &sampleTimingInfo,
                                                 sampleBufferOut: &buffer)

        framesAlreadyWritten += 1
        let sample = VideoSample(buffer: buffer!, format: Image.Format.BGRA)

        self.notify { observer in
            observer.videoSource(self, didOutput: sample)
        }
    }

    func makePixelBuffer() -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferOpenGLESCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferOpenGLESTextureCacheCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(Constants.frameWidth), Int(Constants.frameWidth), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(Constants.frameWidth), height: Int(Constants.frameHeight), bitsPerComponent: Constants.bitsInByte, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        UIGraphicsPushContext(context!)
        let value = CGFloat(sin(Float(framesAlreadyWritten) / (Float(Constants.fps) / Float.pi)) / 2.0 + 0.5)
        let color = UIColor(red: value, green: value, blue: value, alpha: value)
        context!.setFillColor(color.cgColor)
        context!.fill(CGRect(x: 0, y: 0, width: Constants.frameWidth, height: Constants.frameHeight))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }
    func make(from pixelBuffer: CVPixelBuffer) -> CMFormatDescription? {
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
        return formatDescription
    }
}
