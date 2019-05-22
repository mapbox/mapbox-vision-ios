import Foundation

/**
    Helper class handling observers: storing, releasing, notifying.
    Observers are held weakly by the instance of the class.
    You may inherit your video source from this class or agregate it to avoid handling observers yourself.
*/
open class ObservableVideoSource: NSObject, VideoSource {
    
    /// Provides default value of `isExternal` parameter.
    /// Override if your video source is represented by a module separate from the device.
    open var isExternal = true
    
    /// :nodoc:
    open func add(observer: VideoSourceObserver) {
        let id = ObjectIdentifier(observer)
        observations[id] = Observation(observer: observer)
    }
    
    /// :nodoc:
    open func remove(observer: VideoSourceObserver) {
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }
    
    /// Use this method to notify all observers about newly available `VideoSample` or `CameraParameters`.
    public func notify(_ closure: (VideoSourceObserver) -> Void) {
        observations.forEach { (id, observation) in
            guard let observer = observation.observer else {
                observations.removeValue(forKey: id)
                return
            }
            closure(observer)
        }
    }
    
    private struct Observation {
        weak var observer: VideoSourceObserver?
    }
    
    private var observations = [ObjectIdentifier : Observation]()
}
