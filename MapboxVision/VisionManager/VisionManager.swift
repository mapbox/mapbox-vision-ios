import Foundation
import MapboxVisionNative
import UIKit

enum VisionManagerError: LocalizedError {
    case startRecordingBeforeStart
}

/**
 The main object for registering for events from the SDK, starting and stopping their delivery.
 It also provides some useful functions for performance configuration and data conversion.
 */
public final class VisionManager: BaseVisionManager {
    // MARK: - Public

    // MARK: Lifetime

    /**
     Fabric method for creating a `VisionManager` instance.

     It's only allowed to have one living instance of `VisionManager`.
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

     - Parameter delegate: Delegate for `VisionManager`. Delegate is held as a strong reference until `stop` is called.
     */
    public func start(delegate: VisionManagerDelegate? = nil) {
        switch state {
        case .uninitialized:
            assertionFailure("VisionManager should be initialized before starting")
            return
        case .started:
            assertionFailure("VisionManager is already started")
            return
        case let .initialized(videoSource), let .stopped(videoSource):
            self.delegate = delegate
            state = .started(videoSource: videoSource, delegate: delegate)
        }

        resume()
    }

    /**
     Stop delivering events from `VisionManager`.
     This method also stops recording session if it was started.
     */
    public func stop() {
        guard case let .started(videoSource, _) = state else {
            assertionFailure("VisionManager is not started")
            return
        }

        pause()

        state = .stopped(videoSource: videoSource)
        self.delegate = nil
    }

    /**
     Start recording session. During the session full telemetry and video are recorded to specified path.
     You may use resulted folder to replay recorded session with `VisionRecordManager`.
     This method should only be called after `VisionManager` is started.

     - Parameter path: Path to directory where you'd like session to be recorded.

     - Throws: `VisionManagerError.startRecordingBeforeStart` if method is called when `VisionManager` hasn't been started.
     */
    public func startRecording(to path: String) throws {
        guard case .started = state else {
            throw VisionManagerError.startRecordingBeforeStart
        }
        dependencies.recorder.stop()
        tryRecording(mode: .external(path: path))
    }

    /**
     Stop recording session.
     */
    public func stopRecording() {
        guard case .started = state else {
            assertionFailure("VisionManager should be started and recording")
            return
        }
        dependencies.recorder.stop()
        tryRecording(mode: .internal)
    }

    /**
     Cleanup the state and resources of `VisionManger`.
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
        case started(videoSource: VideoSource, delegate: VisionManagerDelegate?)
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

    private var interruptionStartTime: Date?
    private var currentFrame: CVPixelBuffer?
    private var isStoppedForBackground = false

    private init(dependencies: VisionDependencies, videoSource: VideoSource) {
        self.dependencies = dependencies

        super.init(dependencies: BaseDependencies(
            native: dependencies.native,
            synchronizer: dependencies.synchronizer
        ))

        state = .initialized(videoSource: videoSource)

        dependencies.recorder.delegate = self
    }

    deinit {
        destroy()
    }

    private func startVideoStream() {
        guard case let .started(videoSource, _) = state else { return }
        videoSource.add(observer: self)
    }

    private func stopVideoStream() {
        guard case let .started(videoSource, _) = state else { return }
        videoSource.remove(observer: self)
    }

    private func resume() {
        dependencies.dataProvider.start()
        startVideoStream()
        dependencies.native.start(self)

        tryRecording(mode: .internal)
    }

    private func pause() {
        dependencies.dataProvider.stop()
        stopVideoStream()
        dependencies.native.stop()

        dependencies.recorder.stop()
    }

    override func prepareForBackground() {
        interruptionStartTime = Date()
        guard state.isStarted else { return }
        isStoppedForBackground = true
        pause()
    }

    override func prepareForForeground() {
        stopInterruption()
        guard isStoppedForBackground else { return }
        isStoppedForBackground = false
        resume()
    }

    private func stopInterruption() {
        guard let interruptionStartTime = interruptionStartTime else { return }

        let elapsedTime = Date().timeIntervalSince(interruptionStartTime)
        if elapsedTime >= Constants.foregroundInterruptionResetThreshold {
            dependencies.deviceInfo.reset()
        }
    }

    private func tryRecording(mode: SessionRecorder.Mode) {
        guard mode.isExternal || currentCountry.allowsRecording else { return }
        dependencies.recorder.start(mode: mode)
    }

    override public func onCountryUpdated(_ country: Country) {
        super.onCountryUpdated(country)
        if country.allowsRecording {
            tryRecording(mode: .internal)
        } else if dependencies.recorder.currentMode.isInternal {
            dependencies.recorder.stop()
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

        dependencies.recorder.handleFrame(videoSample.buffer)
        dependencies.native.sensors.setImage(pixelBuffer)
    }

    public func videoSource(_ videoSource: VideoSource, didOutput cameraParameters: CameraParameters) {
        dependencies.native.sensors.setCameraParameters(cameraParameters)
    }
}

extension VisionManager: RecordCoordinatorDelegate {
    func recordingStarted(path: String) {}

    func recordingStopped() {
        trySync()
    }
}

private extension Country {
    var allowsRecording: Bool {
        switch self {
        case .USA, .UK, .other, .unknown:
            return true
        case .china:
            return false
        }
    }
}
