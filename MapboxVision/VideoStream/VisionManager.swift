//
//  VisionManager.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 1/20/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import UIKit
import MapboxVisionCore

/**
    The main object for registering for events from the library, starting and stopping their delivery. It also provides some useful function for performance configuration and data conversion.
*/

public final class VisionManager {
    
    private let dependencies: VisionDependency
    
    private var dataProvider: DataProvider?
    private var backgroundTask = UIBackgroundTaskInvalid
    private var enableSyncObservation: NSKeyValueObservation?
    private var syncOverCellularObservation: NSKeyValueObservation?
    private var hasPendingRecordingRequest = false
    private var interruptionStartTime: Date?
    
    private let sessionManager = SessionManager()
    
    private var isSyncAllowedOverCellular: Bool {
        return UserDefaults.standard.syncOverCellular
    }
    
    private var isSyncEnabled: Bool {
        return UserDefaults.standard.enableSync
    }
    
    private var isSyncAllowed: Bool {
        return isSyncEnabled && (isSyncAllowedOverCellular || dependencies.reachability.connection == .wifi)
    }
    
    // MARK: - Public
    // MARK: Lifetime
    
    /**
        Fabric method for creating VisionManager instance.
     */
    
    public static func create(videoSource: VideoSource, operationMode: OperationMode = .normal) -> VisionManager {
        let dependencies = AppDependency(operationMode: operationMode)
        let manager = VisionManager(dependencies: dependencies, videoSource: videoSource, operationMode: operationMode)
        return manager
    }
    
    /**
        Start delivering events from VisionManager.
        VisionManager is required to be initialized before calling this method.
    */
    
    public func start(delegate: VisionManagerDelegate) {
        switch state {
        case .uninitialized:
            assertionFailure("VisionManager should be initialized before starting")
            return
        case .started:
            assertionFailure("VisionManager is already started")
            return
        case let .initialized(videoSource), let .stopped(videoSource):
            state = .started(videoSource: videoSource, delegate: delegate)
        }
        
        resume()
    }
    
    /**
        Stop delivering events from SDK.
    */
    
    public func stop() {
        guard case let .started(videoSource, _) = state else {
            assertionFailure("VisionManager is not started")
            return
        }
        
        pause()
        
        state = .stopped(videoSource: videoSource)
    }
    
    /**
        Cleanup the state and resources of VisionManger.
    */
    
    public func destroy() {
        guard !state.isUninitialized else { return }
        
        if case .started = state {
            stop()
        }
        
        dependencies.native.destroy()
        state = .uninitialized
    }
    
    // MARK: Performance control
    
    /**
        Performance configuration for machine learning models.
        Default value is merged with dynamic performance mode and high rate.
    */
    
    public var modelPerformanceConfig: ModelPerformanceConfig =
        .merged(performance: ModelPerformance(mode: .dynamic, rate: .high)) {
        didSet {
            guard oldValue != modelPerformanceConfig else { return }
            updateModelPerformanceConfig(modelPerformanceConfig)
        }
    }
    
    // MARK: Utility
    
    /**
        Converts location of the point from screen coordinates to world coordinates.
    */
    
    public func pixelToWorld(screenCoordinate: Point2D) -> WorldCoordinate {
        return dependencies.native.pixel(toWorld: screenCoordinate)
    }
    
    /**
        Converts location of the point from world coordinates to screen coordinates.
    */
    
    public func worldToPixel(worldCoordinate: WorldCoordinate) -> Point2D {
        return dependencies.native.world(toPixel: worldCoordinate)
    }
    
    /**
        Determines estimated country where the device is situated.
        For supported values see `CVACountry`.
    */
    
    public var country: Country
    
    // MARK: - Private
    
    private enum State {
        case uninitialized
        case initialized(videoSource: VideoSource)
        case started(videoSource: VideoSource, delegate: VisionManagerDelegate)
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
        
        var delegate: VisionManagerDelegate? {
            guard case let .started(_, delegate) = self else { return nil }
            return delegate
        }
    }
    
    private var state: State = .uninitialized
    private var notificationObservers = [Any]()
    
    private var operationMode: OperationMode = .normal {
        didSet {
            guard operationMode != oldValue else { return }
            updateOperationMode(operationMode)
        }
    }
    
    private init(dependencies: AppDependency, videoSource: VideoSource, operationMode: OperationMode) {
        self.dependencies = dependencies
        self.operationMode = operationMode
        
        state = .initialized(videoSource: videoSource)
        
        // TODO: retrieve initial value from native when algorightm is implemented
        // country = dependencies.native.country
        country = .USA
        
        dependencies.native.config = .basic

        updateModelPerformanceConfig(modelPerformanceConfig)
        updateOperationMode(operationMode)
        
        registerDefaults()
        
        let realtimeDataProvider = RealtimeDataProvider(dependencies: RealtimeDataProvider.Dependencies(
            native: dependencies.native,
            motionManager: dependencies.motionManager,
            metaInfoManager: dependencies.metaInfoManager
        ))
        
        setDataProvider(realtimeDataProvider)
        
        dependencies.set(platformDelegate: self)
        
        dependencies.recordSynchronizer.delegate = self
        dependencies.recorder.delegate = self
        
        dependencies.reachability.whenReachable = { [weak self] _ in
            guard let `self` = self else { return }
            self.isSyncAllowed ? self.startSync() : self.stopSync()
        }
        dependencies.reachability.whenUnreachable = { [weak self] _ in
            print("Network is unreachable")
            self?.stopSync()
        }
        
        try? dependencies.reachability.startNotifier()
        
        let defaults = UserDefaults.standard
        let settingHandler = { [weak self] (defaults: UserDefaults, change: NSKeyValueObservedChange<Bool>) in
            guard let `self` = self else { return }
            self.isSyncAllowed ? self.startSync() : self.stopSync()
        }
        
        enableSyncObservation = defaults.observe(\.enableSync, changeHandler: settingHandler)
        syncOverCellularObservation = defaults.observe(\.syncOverCellular, changeHandler: settingHandler)
        
        sessionManager.listener = self
    
        subscribeToNotifications()
    }
    
    deinit {
        unsubscribeFromNotifications()
        enableSyncObservation?.invalidate()
        syncOverCellularObservation?.invalidate()
        
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
        dependencies.metaInfoManager.addObserver(self)
        
        dataProvider?.start()
        startVideoStream()
        dependencies.native.start(self)
        
        sessionManager.startSession(interruptionInterval: operationMode.sessionInterval)
    }
    
    private func pause() {
        dependencies.metaInfoManager.removeObserver(self)
        
        dataProvider?.stop()
        stopVideoStream()
        dependencies.native.stop()
        
        sessionManager.stopSession()
    }
    
    private func updateModelPerformanceConfig(_ config: ModelPerformanceConfig) {
        switch config {
        case let .merged(performance):
            dependencies.native.config.useMergeMLModelLaunch = true
            updateSegmentationPerformance(performance)
            updateDetectionPerformance(performance)
        case let .separate(segmentationPerformance, detectionPerformance):
            dependencies.native.config.useMergeMLModelLaunch = false
            updateSegmentationPerformance(segmentationPerformance)
            updateDetectionPerformance(detectionPerformance)
        }
    }
    
    private func updateSegmentationPerformance(_ performance: ModelPerformance) {
        switch ModelPerformanceResolver.coreModelPerformance(for: .segmentation, with: performance) {
        case .fixed(let fps):
            dependencies.native.config.setSegmentationFixedFPS(fps)
        case .dynamic(let minFps, let maxFps):
            dependencies.native.config.setSegmentationDynamicFPS(minFPS: minFps, maxFPS: maxFps)
        }
    }
    
    private func updateDetectionPerformance(_ performance: ModelPerformance) {
        switch ModelPerformanceResolver.coreModelPerformance(for: .detection, with: performance) {
        case .fixed(let fps):
            dependencies.native.config.setDetectionFixedFPS(fps)
        case .dynamic(let minFps, let maxFps):
            dependencies.native.config.setDetectionDynamicFPS(minFPS: minFps, maxFPS: maxFps)
        }
    }
    
    private func updateOperationMode(_ operationMode: OperationMode) {
        dependencies.native.config.useSegmentation = operationMode.usesSegmentation
        dependencies.native.config.useDetection = operationMode.usesDetection
        
        dependencies.recorder.savesSourceVideo = operationMode.savesSourceVideo
        
        UserDefaults.standard.enableSync = operationMode.isSyncEnabled
    }
    
    private func registerDefaults() {
        let defaults = UserDefaults.standard
        defaults.setDefaultValue(true, forKey: VisionSettings.enableSync)
        defaults.setDefaultValue(false, forKey: VisionSettings.syncOverCellular)
    }
    
    private var isStoppedForBackground = false
    private func subscribeToNotifications() {
        let center = NotificationCenter.default
        notificationObservers.append(center.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: .main) { [weak self] _ in
            self?.stopInterruption()
            guard let `self` = self, self.isStoppedForBackground else { return }
            self.isStoppedForBackground = false
            self.resume()
        })
    
        notificationObservers.append(center.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: .main) { [weak self] _ in
            self?.interruptionStartTime = Date()
            guard let `self` = self, self.state.isStarted else { return }
            self.isStoppedForBackground = true
            self.pause()
        })
    }
    
    private func unsubscribeFromNotifications() {
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
    }
    
    private func startSync() {
        guard isSyncAllowed else { return }
        dependencies.recordSynchronizer.sync()
    }
    
    private func stopSync() {
        dependencies.recordSynchronizer.stopSync()
    }
    
    // TODO: refactor to setting data provider on initialization
    private func setDataProvider(_ dataProvider: DataProvider) {
        let isActivated = state.isStarted
        
        pause()
        
        self.dataProvider = dataProvider
        
        if isActivated {
            resume()
        }
    }
    
    private func setRecording(at path: RecordingPath, startTime: UInt) {
        let recordedDataProvider = RecordedDataProvider(dependencies: RecordedDataProvider.Dependencies(
            recordingPath: path,
            startTime: startTime
        ))
        
        DispatchQueue.main.async { [weak self] in
            self?.setDataProvider(recordedDataProvider)
        }
    }
    
    private func stopInterruption() {
        guard let interruptionStartTime = interruptionStartTime else { return }
        
        let elapsedTime = Date().timeIntervalSince(interruptionStartTime)
        if elapsedTime >= Constants.foregroundInterruptionResetThreshold {
            dependencies.deviceInfo.reset()
        }
    }
    
    private func selectRecording(at url: URL) {
        guard let recordingPath = RecordingPath(existing: url.path, settings: operationMode.videoSettings) else { return }
        setRecording(at: recordingPath, startTime: 0)
    }
    
    private var currentFrame: CVPixelBuffer?
}

extension VisionManager: VisionDelegate {
    public func onClientUpdate() {
        state.delegate?.visionManagerDidFinishUpdate(self)
    }
    
    public func onSegmentationUpdated(_ segmentation: FrameSegmentation) {
        state.delegate?.visionManager(self, didUpdateFrameSegmentation: segmentation)
    }
    
    public func onDetectionUpdated(_ detections: FrameDetections) {
        state.delegate?.visionManager(self, didUpdateFrameDetections: detections)
    }
    
    public func onSignsUpdated(_ signs: FrameSigns) {
        state.delegate?.visionManager(self, didUpdateFrameSigns: signs)
    }
    
    public func onRoadUpdated(_ road: RoadDescription) {
        state.delegate?.visionManager(self, didUpdateRoadDescription: road)
    }
    
    public func onWorldUpdated(_ world: WorldDescription) {
        state.delegate?.visionManager(self, didUpdateWorldDescription: world)
    }
    
    public func onVehicleLocationUpdated(_ vehicleLocation: VehicleLocation) {
        state.delegate?.visionManager(self, didUpdateVehicleLocation: vehicleLocation)
    }
    
    public func onCameraUpdated(_ camera: Camera) {
        state.delegate?.visionManager(self, didUpdateCamera: camera)
    }
}

extension VisionManager: VideoSourceObserver {
    public func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {
        guard let pixelBuffer = videoSample.buffer.pixelBuffer else {
            assertionFailure("Sample buffer containing pixel buffer is expected here")
            return
        }
        
        currentFrame = pixelBuffer
        
        guard state.isStarted else { return }
        
        dependencies.recorder.handleFrame(videoSample.buffer)
        
        dependencies.native.setImage(pixelBuffer)
    }
    
    public func videoSource(_ videoSource: VideoSource, didOutput cameraParameters: CameraParameters) {
        dependencies.native.setCameraParameters(cameraParameters)
    }
}

extension VisionManager: SyncDelegate {
    func syncStarted() {
        backgroundTask = UIApplication.shared.beginBackgroundTask()
    }
    
    func syncStopped() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
    }
}

extension VisionManager: RecordCoordinatorDelegate {
    func recordingStarted(path: String) {
        dependencies.native.startSavingSession(path)
    }
    
    func recordingStopped() {
        startSync()
        
        if hasPendingRecordingRequest {
            hasPendingRecordingRequest = false
            try? dependencies.recorder.startRecording(referenceTime: dependencies.native.getSeconds(),
                                                      videoSettings: operationMode.videoSettings)
        }
    }
}

extension VisionManager: SessionDelegate {
    func sessionStarted() {
        do {
            try dependencies.recorder.startRecording(referenceTime: dependencies.native.getSeconds(),
                                                     videoSettings: operationMode.videoSettings)
        } catch RecordCoordinatorError.cantStartNotReady {
            hasPendingRecordingRequest = true
        } catch {
            print(error)
        }
    }
    
    func sessionStopped() {
        dependencies.native.stopSavingSession()
        dependencies.recorder.stopRecording()
    }
}

extension VisionManager: MetaInfoObserver {
    func location(_ location: CLLocation) {}
    
    func heading(_ heading: CLHeading) {}
}

extension VisionManager: PlatformDelegate {
    func countryChanged(_ country: Country) {
        self.country = country
    }
}

fileprivate extension VideoSettings {
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
}

private extension UserDefaults {
    @objc dynamic var enableSync: Bool {
        get {
            return bool(forKey: VisionSettings.enableSync)
        }
        set {
            set(newValue, forKey: VisionSettings.enableSync)
        }
    }
    
    @objc dynamic var syncOverCellular: Bool {
        return bool(forKey: VisionSettings.syncOverCellular)
    }
}
