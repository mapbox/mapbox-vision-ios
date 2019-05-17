//
//  ReplayVisionManager.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 5/17/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation
import CoreMedia

public final class ReplayVisionManager: BaseVisionManager {

    public static func create(recordPath: String) throws -> ReplayVisionManager {
        return ReplayVisionManager(dependencies: try ReplayDependencies.default(recordPath: recordPath))
    }

    public var videoSource: VideoSource {
        return dependencies.player
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
        case .initialized, .stopped:
            self.delegate = delegate
            state = .started
        }

        resume()
    }

    /**
     Stop delivering events from `VisionManager`.
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

    private let dependencies: ReplayDependencies
    private var state: State = .uninitialized

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

extension ReplayVisionManager: VideoSourceObserver {
    public func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {
        var timingInfo = CMSampleTimingInfo.invalid
        let status = CMSampleBufferGetSampleTimingInfo(videoSample.buffer, at: 0, timingInfoOut: &timingInfo)

        guard
            let pixelBuffer = videoSample.buffer.pixelBuffer,
            status == 0
        else { return }

        let timeStamp = UInt(CMTimeGetSeconds(timingInfo.decodeTimeStamp) * 1000)

        dependencies.native.sensors.setFrame(pixelBuffer, timestamp: timeStamp)
    }
}

extension ReplayVisionManager: VideoPlayerDelegate {
    func playbackDidStart() {}

    func playbackDidFinish() {
        stop()
    }
}
