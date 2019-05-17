//
//  VisionManager.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 1/20/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import UIKit
import MapboxVisionNative

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
        
        dependencies.recorder.start()
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
    
    public override func onCountryUpdated(_ country: Country) {
        switch country {
        case .USA, .other, .unknown:
            dependencies.recorder.start()
        case .china:
            dependencies.recorder.stop(abort: true)
        }
        super.onCountryUpdated(country)
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
