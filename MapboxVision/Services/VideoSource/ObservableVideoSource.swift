import Foundation

/**
 Helper class handling observers: storing, releasing, notifying.
 Observers are held weakly by the instance of the class.
 You may inherit your video source from this class to avoid handling observers yourself.

 - Warning:
 The implementation uses a recursive lock, thus you must not call `add(observer:)` or `remove(observer:)` methods from `notify` closure.
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

    /**
     Adds an entry to the list of observers.

     The method is a thread-safe.

     - Parameters:
         - observer: Object registering as an observer.

     - Warning:
     The implementation uses a recursive lock, thus you must not call this method from `notify(closure:)` method's closure.
    */
    open func add(observer: VideoSourceObserver) {
        os_unfair_lock_lock(lock)
        let id = ObjectIdentifier(observer)
        observations[id] = Observation(observer: observer)
        os_unfair_lock_unlock(lock)
    }

    /**
     Removes matching entry from the list of observers.

     The method is a thread-safe.

     - Parameters:
         - observer: Object registering as an observer.

     - Warning:
     The implementation uses a recursive lock, thus you must not call this method inside `notify(closure:)`method's closure.
     */
    open func remove(observer: VideoSourceObserver) {
        os_unfair_lock_lock(lock)
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
        os_unfair_lock_unlock(lock)
    }

    // MARK: - Public functions

    /**
     Use this method to notify all observers about newly available `VideoSample` or `CameraParameters`.

     The method is a thread-safe.

     - Parameters:
         - closure: Closure that is called for each entry from the  list of observers. It has a reference to a current observer as a parameter.

     - Warning:
     The implementation uses a recursive lock, thus you must not call `add(observer:)` or `remove(observer:)` methods from  closure.
     */
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
