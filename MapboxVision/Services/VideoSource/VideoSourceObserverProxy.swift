import Foundation
import MapboxVisionNative

class VideoSourceObserverProxy: MBVVideoSource, VideoSourceObserver {
    private let videoSource: VideoSource
    private var observers = [ObjectIdentifier: Observation]()

    private struct Observation {
        weak var observer: MBVVideoSourceObserver?
    }

    init(withVideoSource videoSource: VideoSource) {
        self.videoSource = videoSource
        videoSource.add(observer: self)
    }

    func add(observer: MBVVideoSourceObserver) {
        let id = ObjectIdentifier(observer)
        observers[id] = Observation(observer: observer)
    }

    func remove(observer: MBVVideoSourceObserver) {
        let id = ObjectIdentifier(observer)
        observers.removeValue(forKey: id)
    }

    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {
        observers.forEach { id, observation in
            guard let observer = observation.observer else {
                observers.removeValue(forKey: id)
                return
            }
            observer.videoSource?(self, didOutputVideoSample: videoSample)
        }
    }

    func videoSource(_ videoSource: VideoSource, didOutput cameraParameters: CameraParameters) {
        observers.forEach { id, observation in
            guard let observer = observation.observer else {
                observers.removeValue(forKey: id)
                return
            }
            observer.videoSource?(self, didOutputCameraParameters: cameraParameters)
        }
    }
}
