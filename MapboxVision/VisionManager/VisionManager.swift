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
     Set the camera height above the road surface.

     - Parameter cameraHeight: Camera height in meters.
     */
    public func set(cameraHeight: Float) {
        dependencies.native.set(cameraHeight: cameraHeight)
    }


    /**
     Sets flag to control telemetry sending.

     SDK sends anonymous telemetry to servers. This telemetry goes through additional
     anonymization and is used to improve the quality of the Vision SDK service.

     This flag allows disabling telemetry sending only for accounts
     that were allowed to do that.

     - Parameter telemetrySendingEnabled: Flag to enable/disable telemetry recording.
     */
    public func set(telemetrySendingEnabled: Bool) {
        dependencies.native.set(telemetrySendingEnabled: telemetrySendingEnabled)
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

    // MARK: - Internal

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

        dependencies.native.videoSource = VideoSourceObserverProxy(withVideoSource: videoSource)

        cleanupTelemetry()
    }

    deinit {
        destroy()
    }

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
    }

    private func pause() {
        dependencies.dataProvider.stop()
        stopVideoStream()
        dependencies.native.stop()
    }

    // Removes old recordings and telemetry since new paths are used in core.
    // Added in 0.11.0. Remove after reaching major adoption of 0.11.0 or later versions.
    private func cleanupTelemetry() {
        let locations: [DocumentsLocation] = [.cache, .currentRecording, .recordings(.china), .recordings(.other)]
        locations.forEach { location in
            try? FileManager.default.removeItem(atPath: location.path)
        }
    }
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
        dependencies.native.sensors.setVideoSample(videoSample)
    }

    public func videoSource(_ videoSource: VideoSource, didOutput cameraParameters: CameraParameters) {
        dependencies.native.sensors.setCameraParameters(cameraParameters)
    }
}
