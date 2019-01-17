//
// Created by Alexander Pristavko on 2019-01-17.
// Copyright (c) 2019 Mapbox. All rights reserved.
//

import Foundation

public struct CameraParameters {
    public let width: Int
    public let height: Int
    public let focalLength: Float?
    public let fieldOfView: Float?
    
    public init(width: Int, height: Int, focalLength: Float? = nil, fieldOfView: Float? = nil) {
        self.width = width
        self.height = height
        self.focalLength = focalLength
        self.fieldOfView = fieldOfView
    }
}

public struct VideoSample {
    public let buffer: CMSampleBuffer
    public let parameters: CameraParameters
    
    public init(buffer: CMSampleBuffer, parameters: CameraParameters) {
        self.buffer = buffer
        self.parameters = parameters
    }
}

protocol VideoSource: Streamable {
    typealias Output = (VideoSample) -> Void
    
    var videoSampleOutput: Output? { get set }
}
