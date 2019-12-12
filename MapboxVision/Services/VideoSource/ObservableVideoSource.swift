import Foundation

/**
 Helper class handling observers: storing, releasing, notifying.
 Observers are held weakly by the instance of the class.
 You may inherit your video source from this class to avoid handling observers yourself.
 */
open class ObservableVideoSource: NSObject, VideoSource {
    // MARK: - Open properties

    /// Provides default value of `isExternal` parameter.
    /// Override if your video source is represented by a module separate from the device.
    open var isExternal = true

    // MARK: - Private properties

    private var observations = [ObjectIdentifier: Observation]()
    private var lock: UnsafeMutablePointer<os_unfair_lock>

    // MARK: - Lifecycle

    override public init() {
        lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deallocate()
    }

    // MARK: - Open functions

    /// :nodoc:
    open func add(observer: VideoSourceObserver) {
        os_unfair_lock_lock(lock)
        let id = ObjectIdentifier(observer)
        observations[id] = Observation(observer: observer)
        os_unfair_lock_unlock(lock)
    }

    /// :nodoc:
    open func remove(observer: VideoSourceObserver) {
        os_unfair_lock_lock(lock)
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
        os_unfair_lock_unlock(lock)
    }

    // MARK: - Public functions
    /// Use this method to notify all observers about newly available `VideoSample` or `CameraParameters`.
    public func notify(_ closure: (VideoSourceObserver) -> Void) {
        os_unfair_lock_lock(lock)
        observations.forEach { id, observation in
            guard let observer = observation.observer else {
                observations.removeValue(forKey: id)
                return
            }
            closure(observer)
        }
        os_unfair_lock_unlock(lock)
    }
}

private struct Observation {
    weak var observer: VideoSourceObserver?
}
