//
//  VideoSampler.swift
//  cv-assist-ios
//
//  Created by Maksim on 12/11/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import Foundation
import AVFoundation
import ModelIO

final class VideoSampler: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, Streamable {
    
    typealias Handler = (CMSampleBuffer) -> Void
    
    private let settings: VideoSettings

    private let mdlCamera = MDLCamera()
    
    private let cameraSession: AVCaptureSession
    private let camera: AVCaptureDevice?
    private var dataOutput: AVCaptureVideoDataOutput?
    
    var didCaptureFrame: Handler?
    
    init(settings: VideoSettings) {
        self.settings = settings
        self.cameraSession = AVCaptureSession()
        self.camera = AVCaptureDevice.default(for: .video)
        
        super.init()
        
        configureSession()
        
        orientationChanged()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged),
                                               name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    func start() {
        guard !cameraSession.isRunning else { return }
        cameraSession.startRunning()
    }
    
    func stop() {
        guard cameraSession.isRunning else { return }
        cameraSession.stopRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        didCaptureFrame?(sampleBuffer)
    }
    
    var focalLenght: Float {
        return mdlCamera.focalLength
    }
    
    var fieldOfView: Float {
        return camera?.activeFormat.videoFieldOfView ?? 0
    }
    
    // MARK: - Private
    
    private func configureSession() {
        guard let preset = settings.sessionPreset else { return }
        
        cameraSession.sessionPreset = preset
        
        guard let captureDevice = camera
            else { return }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice)
            else { return }
        
        cameraSession.beginConfiguration()
        
        if cameraSession.canAddInput(deviceInput) {
            cameraSession.addInput(deviceInput)
        }
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: kCVPixelFormatType_32BGRA)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if (cameraSession.canAddOutput(dataOutput) == true) {
            cameraSession.addOutput(dataOutput)
        }
        
        cameraSession.commitConfiguration()
        
        let queue = DispatchQueue(label: "com.mapbox.videoQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        
        self.dataOutput = dataOutput
    }
    
    // MARK: - Observations
    
    @objc private func orientationChanged() {
        dataOutput?.connection(with: .video)?.set(deviceOrientation: UIDevice.current.orientation)
    }
}
