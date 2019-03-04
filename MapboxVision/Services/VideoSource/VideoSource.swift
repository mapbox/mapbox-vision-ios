//
// Created by Alexander Pristavko on 2019-01-17.
// Copyright (c) 2019 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionCore

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

public struct VideoSample {
    public let buffer: CMSampleBuffer
    public let format: Image.Format
    
    public init(buffer: CMSampleBuffer, format: Image.Format) {
        self.buffer = buffer
        self.format = format
    }
}

public protocol VideoSource: class {
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
