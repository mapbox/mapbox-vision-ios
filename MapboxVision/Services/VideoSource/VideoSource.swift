import CoreMedia
import Foundation
import MapboxVisionNative

/**
 Protocol which represents the source of video stream along with meta-information to its observers.
 */
public protocol VideoSource: AnyObject {
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
public protocol VideoSourceObserver: AnyObject {
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample)

    func videoSource(_ videoSource: VideoSource, didOutput cameraParameters: CameraParameters)
}

public extension VideoSourceObserver {
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {}

    func videoSource(_ videoSource: VideoSource, didOutput cameraParameters: CameraParameters) {}
}
