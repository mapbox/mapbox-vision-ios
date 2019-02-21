//
//  CameraVideoSource.swift
//  cv-assist-ios
//
//  Created by Maksim on 12/11/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import Foundation
import AVFoundation

public protocol CameraVideoSourceDelegate: class {
    
    func cameraVideoSource(_ cameraVideoSource: CameraVideoSource, didOutput videoSample: CMSampleBuffer)
    
    func cameraVideoSourceShouldStart(_ cameraVideoSource: CameraVideoSource) -> Bool
    
    func cameraVideoSourceShouldStop(_ cameraVideoSource: CameraVideoSource) -> Bool
}

extension CameraVideoSourceDelegate {
    
    func cameraVideoSourceShouldStart(_ cameraVideoSource: CameraVideoSource) -> Bool { return false }
    
    func cameraVideoSourceShouldStop(_ cameraVideoSource: CameraVideoSource) -> Bool { return false }
}

open class CameraVideoSource: NSObject {
    
    public weak var delegate: CameraVideoSourceDelegate?
    
    public let cameraSession: AVCaptureSession
    
    private let camera: AVCaptureDevice?
    private var dataOutput: AVCaptureVideoDataOutput?
    private var videoSampleOutput: VideoSampleOutput?
    private var cameraParametersOutput: CameraParametersOutput?
    
    public init(preset: AVCaptureSession.Preset = .iFrame960x540) {
        self.cameraSession = AVCaptureSession()
        self.camera = AVCaptureDevice.default(for: .video)
        
        super.init()
        
        configureSession(preset: preset)
        
        orientationChanged()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged),
                                               name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    public func start() {
        guard !cameraSession.isRunning else { return }
        cameraSession.startRunning()
    }
    
    public func stop() {
        guard !cameraSession.isRunning else { return }
        cameraSession.startRunning()
    }
    
    // MARK: - Private
    
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
        dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: kCVPixelFormatType_32BGRA)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if (cameraSession.canAddOutput(dataOutput) == true) {
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
        
        let focalPixelX: Float?
        let focalPixelY: Float?
        
        if let attachment = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) as? Data {
            let matrix: matrix_float3x3 = attachment.withUnsafeBytes { $0.pointee }
            focalPixelX = matrix[0,0]
            focalPixelY = matrix[1,1]
        } else {
            focalPixelX = formatFieldOfView
            focalPixelY = formatFieldOfView
        }
        
        return CameraParameters(width: width, height: height, focalXPixels: focalPixelX, focalYPixels: focalPixelY)
    }
    
    private var formatFieldOfView: Float? {
        guard let fov = camera?.activeFormat.videoFieldOfView else { return nil }
        return fov > 0 ? fov : nil
    }
    
    // MARK: - Observations
    
    @objc private func orientationChanged() {
        dataOutput?.connection(with: .video)?.set(deviceOrientation: UIDevice.current.orientation)
    }
}

extension CameraVideoSource: VideoSource {
    
    open var isExternal: Bool {
        return false
    }
    
    open func attach(_ observer: AnyObject, videoSampleOutput: @escaping VideoSampleOutput, cameraParametersOutput: @escaping CameraParametersOutput) {
        self.videoSampleOutput = videoSampleOutput
        self.cameraParametersOutput = cameraParametersOutput
        
        if let delegate = delegate, !delegate.cameraVideoSourceShouldStart(self) { return }
        start()
    }
    
    open func detach(_ observer: AnyObject) {
        self.videoSampleOutput = nil
        self.cameraParametersOutput = nil
        
        if let delegate = delegate, !delegate.cameraVideoSourceShouldStart(self) { return }
        stop()
    }
}

extension CameraVideoSource: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    open func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let sample = VideoSample(buffer: sampleBuffer, format: .bgra)
        videoSampleOutput?(sample)
        
        delegate?.cameraVideoSource(self, didOutput: sampleBuffer)
        
        if let cameraParameters = getCameraParameters(sampleBuffer: sampleBuffer) {
            cameraParametersOutput?(cameraParameters)
        }
    }
    
    open func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var mode: CMAttachmentMode = 0
        guard let reason = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_DroppedFrameReason, &mode) else { return }
        print("Sample buffer was dropped. Reason: \(reason)")
    }
}
