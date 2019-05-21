import Foundation
import MapboxVisionNative
import CoreMedia

/**
    Structure that encapsulates image buffer and its format.
*/
public struct VideoSample {
    public let buffer: CMSampleBuffer
    public let format: Image.Format
    
    public init(buffer: CMSampleBuffer, format: Image.Format) {
        self.buffer = buffer
        self.format = format
    }
}

/**
    Protocol which represents the source of video stream along with meta-information to its observers.
*/
public protocol VideoSource: class {
    
    /// Determines whether video stream is coming from a camera attached to the device or represented by a separate module.
    var isExternal: Bool { get }
    
    /**
        Add observer of `VideoSource`.
    */
    func add(observer: VideoSourceObserver)
    
    /**
        Remove observer of `VideoSource`.
    */
    func remove(observer: VideoSourceObserver)
}

/**
    Observer of a video source.
*/
public protocol VideoSourceObserver: class {
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample)
    
    func videoSource(_ videoSource: VideoSource, didOutput cameraParameters: CameraParameters)
}

public extension VideoSourceObserver {
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {}
    
    func videoSource(_ videoSource: VideoSource, didOutput cameraParameters: CameraParameters) {}
}
