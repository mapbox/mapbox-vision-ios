//
// Created by Alexander Pristavko on 2019-01-17.
// Copyright (c) 2019 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionCore
import CoreMedia

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

public extension VideoSourceObserver {
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {}
    
    func videoSource(_ videoSource: VideoSource, didOutput cameraParameters: CameraParameters) {}
}
