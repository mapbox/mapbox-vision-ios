//
// Created by Alexander Pristavko on 2019-01-17.
// Copyright (c) 2019 Mapbox. All rights reserved.
//

import Foundation

public struct CameraParameters {
    public let width: Int
    public let height: Int
    public let focalXPixels: Float?
    public let focalYPixels: Float?
    
    public init(width: Int, height: Int, focalXPixels: Float? = nil, focalYPixels: Float? = nil) {
        self.width = width
        self.height = height
        self.focalXPixels = focalXPixels
        self.focalYPixels = focalYPixels
    }
}

// TODO: use core type
public enum InputImageFormat {
    case rgb
    case bgr
    case rgba
    case bgra
}

public struct VideoSample {
    public let buffer: CMSampleBuffer
    public let format: InputImageFormat
    
    public init(buffer: CMSampleBuffer, format: InputImageFormat) {
        self.buffer = buffer
        self.format = format
    }
}

public protocol VideoSource: class {
    typealias VideoSampleOutput = (VideoSample) -> Void
    typealias CameraParametersOutput = (CameraParameters) -> Void
    
    var isExternal: Bool { get }
    
    func add(observer: VideoSourceObserver)
    func remove(observer: VideoSourceObserver)
}

public protocol VideoSourceObserver: class {
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample)
    
    func videoSource(_ videoSource: VideoSource, didOutput cameraParameters: CameraParameters)
}

extension VideoSourceObserver {
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {}
    
    func videoSource(_ videoSource: VideoSource, didOutput cameraParameters: CameraParameters) {}
}
