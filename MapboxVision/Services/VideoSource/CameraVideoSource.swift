import AVFoundation
import Foundation
import MapboxVisionNative

private let imageOutputFormat = Image.Format.BGRA

/**
    Object encapsulating work with camera device.
*/
open class CameraVideoSource: ObservableVideoSource {
    /// Capture session utilized by camera.
    public let cameraSession: AVCaptureSession

    /**
        Create camera video source.
        
        - Parameter preset: Preset for camera session.
    */
    public init(preset: AVCaptureSession.Preset = .iFrame960x540) {
        self.cameraSession = AVCaptureSession()
        self.camera = AVCaptureDevice.default(for: .video)

        super.init()

        isExternal = false

        configureSession(preset: preset)

        set(orientation: UIApplication.shared.statusBarOrientation.deviceOrientation)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    /**
        Start running camera video source.
    */
    public func start() {
        guard !cameraSession.isRunning else { return }
        cameraSession.startRunning()
    }

    /**
        Stop running camera video source.
    */
    public func stop() {
        guard cameraSession.isRunning else { return }
        cameraSession.stopRunning()
    }

    // MARK: - Private

    private let camera: AVCaptureDevice?
    private var dataOutput: AVCaptureVideoDataOutput?

    private func configureSession(preset: AVCaptureSession.Preset) {
        guard let captureDevice = camera
            else { return }

        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice)
            else { return }

        cameraSession.beginConfiguration()

        cameraSession.sessionPreset = preset

        if cameraSession.canAddInput(deviceInput) {
            cameraSession.addInput(deviceInput)
        }

        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: imageOutputFormat.pixelFormatType)]
        dataOutput.alwaysDiscardsLateVideoFrames = true

        if cameraSession.canAddOutput(dataOutput) {
            cameraSession.addOutput(dataOutput)
        }

        if let connection = dataOutput.connection(with: .video), connection.isCameraIntrinsicMatrixDeliverySupported {
            connection.isCameraIntrinsicMatrixDeliveryEnabled = true
        }

        cameraSession.commitConfiguration()

        let queue = DispatchQueue(label: "com.mapbox.videoQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)

        self.dataOutput = dataOutput
    }

    private func getCameraParameters(sampleBuffer: CMSampleBuffer) -> CameraParameters? {
        guard let pixelBuffer = sampleBuffer.pixelBuffer else { return nil }

        let width = pixelBuffer.width
        let height = pixelBuffer.height

        let focalPixelX: Float
        let focalPixelY: Float

        if let attachment = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) as? Data {
            let matrix: matrix_float3x3 = attachment.withUnsafeBytes { $0.pointee }
            focalPixelX = matrix[0,0]
            focalPixelY = matrix[1,1]
        } else if let fov = formatFieldOfView {
            let pixel = CameraVideoSource.focalPixel(fov: fov, dimension: width)
            focalPixelX = pixel
            focalPixelY = pixel
        } else {
            focalPixelX = -1
            focalPixelY = -1
        }

        return CameraParameters(width: width, height: height, focalXPixels: focalPixelX, focalYPixels: focalPixelY)
    }

    private var formatFieldOfView: Float? {
        guard let fov = camera?.activeFormat.videoFieldOfView else { return nil }
        return fov > 0 ? fov : nil
    }

    private static func focalPixel(fov: Float, dimension: Int) -> Float {
        let measurement = Measurement(value: Double(fov), unit: UnitAngle.degrees)
        return (Float(dimension) / 2) / tan(Float(measurement.converted(to: .radians).value) / 2)
    }

    private func set(orientation: UIDeviceOrientation) {
        dataOutput?.connection(with: .video)?.set(deviceOrientation: orientation)
    }

    // MARK: - Observations

    @objc
    private func orientationChanged() {
        set(orientation: UIDevice.current.orientation)
    }
}

/// :nodoc:
extension CameraVideoSource: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        notify { (observer) in
            let sample = VideoSample(buffer: sampleBuffer, format: imageOutputFormat)
            observer.videoSource(self, didOutput: sample)

            if let cameraParameters = getCameraParameters(sampleBuffer: sampleBuffer) {
                observer.videoSource(self, didOutput: cameraParameters)
            }
        }
    }

    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var mode: CMAttachmentMode = 0
        guard let reason = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_DroppedFrameReason, attachmentModeOut: &mode) else { return }
        print("Sample buffer was dropped. Reason: \(reason)")
    }
}

extension UIInterfaceOrientation {
    var deviceOrientation: UIDeviceOrientation {
        switch self {
        case .unknown:
            return .unknown
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        }
    }
}

private extension Image.Format {
    var pixelFormatType: OSType {
        switch self {
        case .unknown:
            return 0
        case .RGBA:
            return kCVPixelFormatType_32RGBA
        case .BGRA:
            return kCVPixelFormatType_32BGRA
        case .RGB:
            return kCVPixelFormatType_24RGB
        case .BGR:
            return kCVPixelFormatType_24BGR
        case .grayscale8:
            return kCVPixelFormatType_8Indexed
        }
    }
}
