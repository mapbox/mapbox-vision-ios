import CoreMedia
import Foundation

/**
 `VisionReplayManager` is a counterpart of `VisionManager` that uses recorded video and telemetry instead of realtime data.
 Use it to debug and test functions that use Vision in a development environment before testing in a vehicle.
 Use it in the same workflow as you use `VisionManager` after creating it with specific recorded session.

 Lifecycle of VisionReplayManager :
 1. `create`
 2. `start`
 3. `stop`, then lifecycle may proceed with `destroy` or `start`
 4. `destroy`

 - Important: This class is intended for debugging purposes only.
 Do NOT use session replay in production application.
 */
public final class VisionReplayManager: BaseVisionManager {
    /**
     Fabric method for creating a `VisionReplayManager` instance.

     It's only allowed to have one living instance of `VisionManager` or `VisionReplayManager`.
     To create `VisionReplayManager` with a different configuration call `destroy` on existing instance or release all references to it.

     - Important: Do NOT call this method more than once.

     - Parameter recordPath: Path to a folder with recorded session. You typically record such sessions using `startRecording` / `stopRecording` on `VisionManager`.

     - Returns: Instance of `VisionReplayManager` configured to use data from specified session.
     */
    public static func create(recordPath: String) throws -> VisionReplayManager {
        return VisionReplayManager(dependencies: try ReplayDependencies.default(recordPath: recordPath))
    }

    /**
     Video source that provides frames from recorded video.
     */
    public var videoSource: VideoSource {
        return dependencies.player
    }

    /**
     Start delivering events from `VisionReplayManager`.
     Calling `start` on already started or destroyed instance is considered a mistake.

     - Important: Do NOT call this method more than once or after `destroy` is called.

     - Parameter delegate: Delegate for `VisionReplayManager`. Delegate is held as a strong reference until `stop` is called.
     */
    public func start(delegate: VisionManagerDelegate? = nil) {
        switch state {
        case .uninitialized:
            assertionFailure("VisionManager should be initialized before starting")
            return
        case .started:
            assertionFailure("VisionManager is already started")
            return
        case .initialized, .stopped:
            self.delegate = delegate
            state = .started
        }

        resume()
    }

    /**
     Stop delivering events from `VisionReplayManager`.

     - Important: Do NOT call this method more than once or before `start` or after `destroy` is called.
     */
    public func stop() {
        guard state == .started else {
            assertionFailure("VisionManager is not started")
            return
        }

        pause()

        state = .stopped
        delegate = nil
    }

    /**
     Clean up the state and resources of `VisionReplayManager`.

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

    // MARK: Initialization

    init(dependencies: ReplayDependencies) {
        self.dependencies = dependencies
        super.init(dependencies: BaseDependencies(native: dependencies.native, synchronizer: dependencies.synchronizer))

        dependencies.player.add(observer: self)
        dependencies.player.delegate = self

        state = .initialized
    }

    deinit {
        destroy()
    }

    // MARK: Private

    private let dependencies: ReplayDependencies
    private var state: State = .uninitialized

    private enum State {
        case uninitialized
        case initialized
        case started
        case stopped

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

    private func resume() {
        dependencies.native.start(self)
        dependencies.player.start()
    }

    private func pause() {
        dependencies.native.stop()
        dependencies.player.stop()
    }
}

extension VisionReplayManager: VideoSourceObserver {
    public func videoSource(_: VideoSource, didOutput videoSample: VideoSample) {
        var timingInfo = CMSampleTimingInfo.invalid
        let status = CMSampleBufferGetSampleTimingInfo(videoSample.buffer, at: 0, timingInfoOut: &timingInfo)

        guard
            let pixelBuffer = videoSample.buffer.pixelBuffer,
            status == 0
        else { return }

        let timeStamp = UInt(CMTimeGetSeconds(timingInfo.decodeTimeStamp) * Constants.millisecondsInSecond)

        dependencies.native.sensors.setFrame(pixelBuffer, timestamp: timeStamp)
    }
}

extension VisionReplayManager: VideoPlayerDelegate {
    func playbackDidStart() {}

    func playbackDidFinish() {
        stop()
    }
}
