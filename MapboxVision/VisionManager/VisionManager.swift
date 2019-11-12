import Foundation
import MapboxVisionNative
import UIKit

enum VisionManagerError: LocalizedError {
    case startRecordingBeforeStart
}

/**
 The main object for registering for events from the SDK, starting and stopping their delivery.
 It also provides some useful functions for performance configuration and data conversion.

 Lifecycle of VisionManager :
 1. `create`
 2. `start`
 3. `startRecording` (optional)
 4. `stopRecording` (optional)
 5. `stop`, then lifecycle may proceed with `destroy` or `start`
 6. `destroy`
 */
public final class VisionManager: BaseVisionManager {
    // MARK: - Public

    /// Delegate for `VisionManager`. Delegate is held as a weak reference.
    public weak var delegate: VisionManagerDelegate? {
        get {
            return baseDelegate
        }
        set {
            baseDelegate = newValue
        }
    }

    // MARK: Lifetime

    /**
     Fabric method for creating a `VisionManager` instance.

     It's only allowed to have one living instance of `VisionManager` or `VisionReplayManager`.
     To create `VisionManager` with different configuration call `destroy` on existing instance or release all references to it.

     - Parameter videoSource: Video source which will be utilized by created instance of `VisionManager`.

     - Returns: Instance of `VisionManager` configured with video source.
     */
    public static func create(videoSource: VideoSource) -> VisionManager {
        let dependencies = VisionDependencies.default()
        let manager = VisionManager(dependencies: dependencies, videoSource: videoSource)
        return manager
    }

    /**
     Start delivering events from `VisionManager`.

     - Important: Do NOT call this method more than once or after `destroy` is called.
     */
    public func start() {
        switch state {
        case .uninitialized:
            assertionFailure("VisionManager should be initialized before starting")
            return
        case .started:
            assertionFailure("VisionManager is already started")
            return
        case let .initialized(videoSource), let .stopped(videoSource):
            state = .started(videoSource: videoSource)
        }

        resume()
    }

    /**
     Stop delivering events from `VisionManager`.

     To resume call `start` again.
     Call this method after `start` and before `destroy`.
     This method also stops recording session if it was started.

     - Important: Do NOT call this method more than once or before `start` or after `destroy` is called.
     */
    public func stop() {
        guard case let .started(videoSource) = state else {
            assertionFailure("VisionManager is not started")
            return
        }

        pause()

        state = .stopped(videoSource: videoSource)
    }

    /**
     Start recording a session.

     During the session full telemetry and video are recorded to specified path.
     You may use resulted folder to replay the recorded session with `VisionReplayManager`.

     - Important: Method serves debugging purposes.
     Do NOT call this method more than once or before `start` or after `stop` is called.
     Do NOT use session recording in production applications.

     - Parameter path: Path to directory where you'd like session to be recorded.

     - Throws: `VisionManagerError.startRecordingBeforeStart` if method is called when `VisionManager` hasn't been started.
     */
    public func startRecording(to path: String) throws {
        guard case .started = state else {
            throw VisionManagerError.startRecordingBeforeStart
        }
        dependencies.native.startRecording(to: path)
    }

    /**
     Stop recording a session.

     - Important: Method serves debugging purposes.
     Do NOT use session recording in production applications.
     Do NOT call this method more than once or before `startRecording` or after `stop` is called.
     */
    public func stopRecording() {
        guard case .started = state else {
            assertionFailure("VisionManager should be started and recording")
            return
        }
        dependencies.native.stopRecording()
    }

    /**
     Clean up the state and resources of `VisionManger`.

     - Important: Do NOT call this method more than once.
     */
    public func destroy() {
        guard !state.isUninitialized else { return }

        if case .started = state {
            stop()
        }

        dependencies.native.destroy()
        state = .uninitialized
    }

    // MARK: - Private

    private enum State {
        case uninitialized
        case initialized(videoSource: VideoSource)
        case started(videoSource: VideoSource)
        case stopped(videoSource: VideoSource)

        var isUninitialized: Bool {
            guard case .uninitialized = self else { return false }
            return true
        }

        var isInitialized: Bool {
            guard case .initialized = self else { return false }
            return true
        }

        var isStarted: Bool {
            guard case .started = self else { return false }
            return true
        }

        var isStopped: Bool {
            guard case .stopped = self else { return false }
            return true
        }
    }

    private let dependencies: VisionDependencies
    private var state: State = .uninitialized

    private var currentCountry = Country.unknown
    private var currentRecordingPath: String?
    private var recordingToCountryCache = [String: Country]()
    private var currentFrame: CVPixelBuffer?
    private var isStoppedForBackground = false

    init(dependencies: VisionDependencies, videoSource: VideoSource) {
        self.dependencies = dependencies

        super.init(dependencies: BaseDependencies(native: dependencies.native))

        state = .initialized(videoSource: videoSource)

//        dependencies.recorder.delegate = self
        dependencies.native.videoSource = VideoSourceObserverProxy(withVideoSource: videoSource)
    }

    deinit {
        destroy()
    }

//    private var isSyncAllowed: Bool {
//        return currentCountry.syncRegion != nil
//    }

    private func startVideoStream() {
        guard case let .started(videoSource) = state else { return }
        videoSource.add(observer: self)
    }

    private func stopVideoStream() {
        guard case let .started(videoSource) = state else { return }
        videoSource.remove(observer: self)
    }

    private func resume() {
        dependencies.dataProvider.start()
        startVideoStream()
        dependencies.native.start()

//        dependencies.recorder.start(mode: .internal)
    }

    private func pause() {
        dependencies.dataProvider.stop()
        stopVideoStream()
        dependencies.native.stop()

//        dependencies.recorder.stop()
    }

//    private func configureRecording(oldCountry: Country, newCountry: Country) {
//        guard
//            state.isStarted,
//            dependencies.recorder.isInternal,
//            let oldRegion = oldCountry.syncRegion,
//            oldRegion != newCountry.syncRegion
//        else { return }
//
//        if let path = currentRecordingPath {
//            recordingToCountryCache[path] = oldCountry
//        }
//        dependencies.recorder.stop()
//        dependencies.recorder.start(mode: .internal)
//    }

//    private func configureSync(oldCountry: Country, newCountry: Country) {
//        if newCountry.syncRegion == nil {
//            dependencies.synchronizer.stopSync()
//            return
//        }
//
//        guard
//            let newRegion = newCountry.syncRegion,
//            oldCountry.syncRegion != newRegion
//        else { return }
//
//        let dataSource = SyncRecordDataSource(region: newRegion)
//        dependencies.synchronizer.stopSync()
//        dependencies.synchronizer.set(dataSource: dataSource, baseURL: newRegion.baseURL)
//        dependencies.synchronizer.sync()
//    }

//    private func trySync() {
//        if isSyncAllowed {
//            dependencies.synchronizer.sync()
//        }
//    }

    override func prepareForBackground() {
        guard state.isStarted else { return }
        isStoppedForBackground = true
        pause()
    }

    override func prepareForForeground() {
        guard isStoppedForBackground else { return }
        isStoppedForBackground = false
        resume()
    }

//    override public func onCountryUpdated(_ country: Country) {
//        let oldCountry = currentCountry
//        currentCountry = country
//
//        configureRecording(oldCountry: oldCountry, newCountry: country)
//        configureSync(oldCountry: oldCountry, newCountry: country)
//
//        super.onCountryUpdated(country)
//    }
}

/// :nodoc:
extension VisionManager: VideoSourceObserver {
    public func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {
        guard let pixelBuffer = videoSample.buffer.pixelBuffer else {
            assertionFailure("Sample buffer containing pixel buffer is expected here")
            return
        }

        currentFrame = pixelBuffer

        guard state.isStarted else { return }

        dependencies.recorder.handle(frame: videoSample.buffer)
        dependencies.native.sensors.setImage(pixelBuffer)
    }

    public func videoSource(_ videoSource: VideoSource, didOutput cameraParameters: CameraParameters) {
        dependencies.native.sensors.setCameraParameters(cameraParameters)
    }
}

//extension VisionManager: RecordCoordinatorDelegate {
//    func recordingStarted(path: String) {
//        currentRecordingPath = path.lastPathComponent
//    }
//
//    func recordingStopped(recordingPath: RecordingPath) {
//        currentRecordingPath = nil
//
//        let country = recordingToCountryCache.removeValue(forKey: recordingPath.recordingPath.lastPathComponent)
//            ?? currentCountry
//
//        try? handle(recordingPath: recordingPath, country: country)
////        trySync()
//    }
//
//    private func handle(recordingPath: RecordingPath, country: Country) throws {
//        guard recordingPath.basePath != .custom else { return }
//
//        guard let syncRegion = country.syncRegion else {
//            try recordingPath.delete()
//            return
//        }
//
//        try recordingPath.move(to: .recordings(syncRegion))
//    }
//}
