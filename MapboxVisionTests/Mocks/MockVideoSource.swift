import Foundation

@testable import MapboxVision

final class MockVideoSource: ObservableVideoSource {
    private enum Constants {
        static let fps: Int32 = 30
        static let frameDelay = 1.0 / Double(fps)
        static let frameWidth = 960
        static let frameHeight = 540
        static let bitsInByte = 8
    }

    private let processingQueue = DispatchQueue(label: "com.mapbox.RecordCoordinatorTest.VideoSource")
    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now() + Constants.frameDelay, repeating: Constants.frameDelay)
        timer.setEventHandler { [weak self] in
            self?.emitNewBuffer()
        }
        return timer
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

    private func emitNewBuffer() {
        var sampleBufferOut: CMSampleBuffer?

        guard let pixelBuffer = makePixelBuffer(), let formatDescription = makeFormatDescription(from: pixelBuffer) else {
            return
        }

        let duration = CMTime(value: 1, timescale: Constants.fps)
        let presentationTimeStamp = CMTime(value: framesAlreadyWritten, timescale: Constants.fps)
        var sampleTimingInfo = CMSampleTimingInfo(duration: duration, presentationTimeStamp: presentationTimeStamp, decodeTimeStamp: CMTime.invalid)
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                 imageBuffer: pixelBuffer,
                                                 formatDescription: formatDescription,
                                                 sampleTiming: &sampleTimingInfo,
                                                 sampleBufferOut: &sampleBufferOut)

        guard let buffer = sampleBufferOut else {
            return
        }

        framesAlreadyWritten += 1
        let sample = VideoSample(buffer: buffer, format: Image.Format.BGRA)

        self.notify { observer in
            observer.videoSource(self, didOutput: sample)
        }
    }

    private func makePixelBuffer() -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue,
        ] as CFDictionary
        var pixelBufferUnwrapped: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(Constants.frameWidth), Int(Constants.frameWidth), kCVPixelFormatType_32BGRA, attrs, &pixelBufferUnwrapped)
        guard status == kCVReturnSuccess, let pixelBuffer = pixelBufferUnwrapped else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: pixelData,
            width: Constants.frameWidth,
            height: Constants.frameHeight,
            bitsPerComponent: Constants.bitsInByte,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }

        UIGraphicsPushContext(context)
        let value = CGFloat(sin(Float(framesAlreadyWritten) / (Float(Constants.fps) / Float.pi)) / 2.0 + 0.5)
        let color = UIColor(red: value, green: value, blue: value, alpha: value)
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: Constants.frameWidth, height: Constants.frameHeight))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }

    private func makeFormatDescription(from pixelBuffer: CVPixelBuffer) -> CMFormatDescription? {
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
        return formatDescription
    }
}
