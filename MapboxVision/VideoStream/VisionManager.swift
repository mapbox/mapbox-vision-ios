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
    The interface that user’s custom object should conform to in order to receive events from SDK.
*/

public protocol VisionManagerDelegate: class {
    /**
        Tells the delegate that new segmentation is available.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateSegmentation segmentation: SegmentationMask?) -> Void
    /**
        Tells the delegate that new detections are available.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateDetections detections: Detections?) -> Void
    /**
        Tells the delegate that new sign classification is available.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateSignClassifications classifications: SignClassifications?) -> Void
    /**
        Tells the delegate that new road description is available. These values are high-frequency but unprocessed.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateRawRoadDescription roadDescription: RoadDescription?) -> Void
    /**
        Tells the delegate that new processed road description is available. These are smoothed and more stable values.
     */
    func visionManager(_ visionManager: VisionManager, didUpdateRoadDescription roadDescription: RoadDescription?) -> Void
    /**
        Tells the delegate that newly estimated position is calculated.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateEstimatedPosition estimatedPosition: Position?) -> Void
    /**
        Tells the delegate that distance to closest car ahead is updated.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateWorldDescription worldDescription: WorldDescription?) -> Void
    /**
        Tells the delegate that lane departure state is updated.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateLaneDepartureState laneDepartureState: LaneDepartureState) -> Void
}

/**
    The interface that allows to receive instructions on how to render navigation route. Object that implements this interface is supposed to display navigation route based on provided instructions.
*/

public protocol VisionManagerARDelegate: class {
    /**
        Provides updated instructions on how to render navigation route.
    */
    func visionManager(_ visionManager: VisionManager, didUpdateManeuverLocation maneuverLocation: ManeuverLocation?) -> Void
}

/**
    The interface that allows managing the presentation state of provided visual components.
*/

public protocol VisionPresentationControllable: class {
    /**
        Set visualization mode which can be either original frame, original frame with segmentation as an overlay or original frame with detections as an overlay.
    */
    var frameVisualizationMode: VisualizationMode { get set }
}

/**
    Interface for visual presentation based on UIViewController 
*/
public typealias VisionPresentationViewController = UIViewController & VisionPresentationControllable

protocol VideoStreamInteractable : VideoStreamInput {
    var output: VideoStreamOutput? { get set }
    
    func selectRecording(at url: URL)
    func startBroadcasting(at timestamp: String)
}

/**
    Visual (debug) mode of neural networks
*/

public enum VisualizationMode {
    /**
        Show a raw frame from the camera
    */
    case clear
    /**
        Show segmentation mask above video stream
    */
    case segmentation
    /**
        Show detected objects with bounding boxes
    */
    case detection
}

protocol VideoStreamInput: class {
    var isFPSTableEnabled: Bool { get set }
    var isWatermarkVisible: Bool { get set }
    
    func toggleDebugOverlay()
    func toggleSegmentationOverlay()
    
    func clearCache(force: Bool)
}

protocol VideoStreamOutput: class {
    func locationUpdated(_ location: CLLocation)
}

private let motionUpdateInterval = 0.02
private let signTrackerMaxCapacity = 5

/**
    The main object for registering for events from the library, starting and stopping their delivery. It also provides some useful function for performance configuration and data conversion.
*/

public final class VisionManager {
    
    /**
     Shared instance of VisionManager.
    */
    
    public static let shared = VisionManager()
    
    /**
        The delegate receiving events from SDK. This is a custom object that user of the SDK provides.
    */
    public weak var delegate: VisionManagerDelegate?
    
    /**
        Set delegate which will receive and handle instructions on rendering AR navigation.
    */
    
    public weak var arDelegate: VisionManagerARDelegate?
    
    @available(*, deprecated, message: "configure presentation with VisionPresentationControllable and performance on manager instance")
    var isFPSTableEnabled: Bool = false {
        didSet {
            if !isFPSTableEnabled {
                presenter?.present(fps: nil)
            }
        }
    }
    
    @available(*, deprecated, message: "configure presentation with VisionPresentationControllable and performance on manager instance")
    var isWatermarkVisible: Bool = false {
        didSet {
            presenter?.present(isWatermarkVisible: isWatermarkVisible)
        }
    }
    
    var output: VideoStreamOutput?
    
    private weak var presenter: VideoStreamPresentable?
    
    private let dependencies: VisionDependency
    
    private var dataProvider: DataProvider?
    private var backgroundTask = UIBackgroundTaskInvalid
    private var hasPendingSyncRequest: Bool = false
    private var isStarted: Bool = false
    private var enableSyncObservation: NSKeyValueObservation?
    private var syncOverCellularObservation: NSKeyValueObservation?
    private var currentRecording: RecordingPath?
    private var hasPendingRecordingRequest = false
    private var videoStream: Streamable
    
    private let sessionManager = SessionManager()
    
    private var isSyncing = false {
        didSet {
            print(isSyncing ? "Syncing..." : "Syncing stopped")
            if !isSyncing, hasPendingSyncRequest {
                startSync()
            }
        }
    }
    
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
        Start delivering events from SDK.
    */
    
    public func start() {
        guard !isStarted else { return }
    
        isStarted = true
    
        dependencies.metaInfoManager.addObserver(self)
    
        dataProvider?.start()
        videoStream.start()
        dependencies.coreUpdater.startUpdating()
    
        sessionManager.startSession(interruptionInterval: operationMode.sessionInterval)
    
        if let recording = currentRecording {
            let videoURL = URL(fileURLWithPath: recording.videoPath)
            presenter?.presentVideo(at: videoURL)
        }
    }
    
    /**
        Stop delivering events from SDK.
    */
    
    public func stop() {
        guard isStarted else { return }
    
        isStarted = false
    
        dependencies.metaInfoManager.removeObserver(self)
    
        dataProvider?.stop()
        videoStream.stop()
        dependencies.coreUpdater.stopUpdating()
    
        sessionManager.stopSession()
    }
    
    // MARK: Performance control
    
    /**
        Used for configuration of segmentation-related tasks performance.
    */
    
    public var segmentationPerformance: ModelPerformance {
        didSet {
            updateSegmentationPerformance(segmentationPerformance)
        }
    }
    
    /**
        Used for configuration of detection-related tasks performance.
    */
    
    public var detectionPerformance: ModelPerformance {
        didSet {
            updateDetectionPerformance(detectionPerformance)
        }
    }
    
    // MARK: Current values
    
    /**
        Current position estimated by SDK defined as a set of location-related parameters.
    */
    
    public var estimatedPosition: Position? {
        didSet {
            guard oldValue?.identifier != estimatedPosition?.identifier else { return }
            delegate?.visionManager(self, didUpdateEstimatedPosition: estimatedPosition)
        }
    }
    
    /**
        Unprocessed description of current road situation.
     */
    
    public var rawRoadDescription: RoadDescription? {
        didSet {
            guard oldValue?.identifier != roadDescription?.identifier else { return }
            delegate?.visionManager(self, didUpdateRawRoadDescription: roadDescription)
        }
    }
    
    /**
        Description of current road situation
    */
    
    public var roadDescription: RoadDescription? {
        didSet {
            guard oldValue?.identifier != roadDescription?.identifier else { return }
            delegate?.visionManager(self, didUpdateRoadDescription: roadDescription)
        }
    }
    
    /**
        World description.
    */
    
    public var worldDescription: WorldDescription? {
        didSet {
            guard oldValue?.identifier != worldDescription?.identifier else { return }
            delegate?.visionManager(self, didUpdateWorldDescription: worldDescription)
        }
    }
    
    /**
        Current lane departure state.
    */
    
    public var laneDepartureState: LaneDepartureState = .normal {
        didSet {
            guard oldValue != laneDepartureState else { return }
            delegate?.visionManager(self, didUpdateLaneDepartureState: laneDepartureState)
        }
    }
    
    // MARK: Presentation
    
    /**
        Create and setup presentation objects. Caller may configure presentation with presenter and display platform-specific view component.
    */
    
    public func createPresentation() -> VisionPresentationViewController {
        let viewController = VisionViewController()
        presenter = viewController
        viewController.interactor = self
        return viewController
    }
    
    // MARK: Navigation
    
    /**
        Provide information about navigation route to get instructions on rendering AR navigation.
    */
    
    public func startNavigation(to route: NavigationRoute) -> Void {
        dependencies.core.setRoute(route)
    }
    
    /**
        Stop navigation.
    */
    
    public func stopNavigation() {
        dependencies.core.setRoute(nil)
    }
    
    // MARK: Utility
    
    /**
        Returns the size of the frame.
    */
    
    public var frameSize: CGSize {
        return dependencies.videoSettings.size
    }
    
    /**
        Converts location of the point from screen coordinates to world coordinates.
    */
    
    public func pixelToWorld(screenCoordinate: CGPoint) -> WorldCoordinate {
        return dependencies.core.pixel(toWorld: screenCoordinate)
    }
    
    /**
        Converts location of the point from world coordinates to screen coordinates.
    */
    
    public func worldToPixel(worldCoordinate: WorldCoordinate) -> CGPoint {
        return dependencies.core.world(toPixel: worldCoordinate)
    }
    
    /**
        Operation mode determines whether vision manager works normally or focuses just on gathering data.
    */
    
    public var operationMode: OperationMode = .normal {
        didSet {
            guard operationMode != oldValue else { return }
            
            dependencies.core.config.useSegmentation = operationMode.usesSegmentation
            dependencies.core.config.useDetection = operationMode.usesDetection
            
            dependencies.recorder.savesSourceVideo = operationMode.savesSourceVideo
            
            UserDefaults.standard.enableSync = operationMode.isSyncEnabled
        }
    }
    
    /**
        Determines whether video stream remains running outside of `start()` and `stop()` calls.
        When property is set to `true` `VisionPresentationViewController` will update background view with frames from camera.
    */
    
    public var isVideoStreamAlwaysRunning = false {
        didSet {
            guard isVideoStreamAlwaysRunning != oldValue else { return }
            
            let sampler = dependencies.videoSampler
            if isVideoStreamAlwaysRunning {
                videoStream = AlwaysRunningStream(stream: sampler)
            } else {
                videoStream = ControlledStream(stream: sampler)
                if !isStarted {
                    videoStream.stop()
                }
            }
        }
    }
    
    // MARK: - Private
    
    private var notificationObservers = [Any]()
    
    private var maneuverLocation: ManeuverLocation? {
        didSet {
            guard maneuverLocation != oldValue else { return }
            arDelegate?.visionManager(self, didUpdateManeuverLocation: maneuverLocation)
        }
    }
    
    private init() {
        self.dependencies = AppDependency()
        self.videoStream = ControlledStream(stream: dependencies.videoSampler)
        self.segmentationPerformance = ModelPerformance(mode: .dynamic, rate: .high)
        self.detectionPerformance = ModelPerformance(mode: .dynamic, rate: .high)
        
        dependencies.core.config = .basic

        updateSegmentationPerformance(segmentationPerformance)
        updateDetectionPerformance(detectionPerformance)
        
        registerDefaults()
        
        let realtimeDataProvider = RealtimeDataProvider(dependencies: RealtimeDataProvider.Dependencies(
            core: dependencies.core,
            motionManager: dependencies.motionManager,
            metaInfoManager: dependencies.metaInfoManager
        ))
        
        setDataProvider(realtimeDataProvider)
        
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
        
        dependencies.coreUpdater.set(updateHandlerQueue: .main) { [weak self] in
            guard let `self` = self else { return }
            
            self.dataProvider?.update()
            
            var overlay: UIImage? = nil
            var fpsValue: FPSValue? = self.dependencies.core.getFPS()
            if self.dependencies.core.config.useDebugOverlay {
                overlay = self.dependencies.core.getDebugOverlay().getUIImage()
                fpsValue = nil
            }
            self.presenter?.present(debugOverlay: overlay)
            
            if self.isFPSTableEnabled {
                self.presenter?.present(fps: fpsValue)
            }
            
            let segmentationMask = self.dependencies.core.getSegmentationMask()
            self.delegate?.visionManager(self, didUpdateSegmentation: segmentationMask)
            
            let detections = self.dependencies.core.getDetections()
            self.delegate?.visionManager(self, didUpdateDetections: detections)
            
            let signClassifications = self.dependencies.core.getSignClassifications()
            self.delegate?.visionManager(self, didUpdateSignClassifications: signClassifications)
            
            self.estimatedPosition = self.dependencies.core.getEstimatedPosition()
            
            self.rawRoadDescription = self.dependencies.core.getRawRoadDescription()
            
            self.roadDescription = self.dependencies.core.getRoadDescription()
            
            self.worldDescription = self.dependencies.core.getWorldDescription()
            
            self.laneDepartureState = self.dependencies.core.getLaneDepartureState()
            
            guard let presenter = self.presenter else { return }
            
            switch presenter.frameVisualizationMode {
            case .clear: break
            case .segmentation:
                presenter.present(segMask: segmentationMask)
            case .detection:
                presenter.present(detections: detections, canvasSize: self.dependencies.videoSettings.size)
            }
            
            let crossroad = self.dependencies.core.getNearestCrossroad()
            let isValidCrossroad = crossroad.routePoint.isManeuver && crossroad.origin.y > 0
            self.maneuverLocation = isValidCrossroad ? ManeuverLocation(origin: crossroad.origin.cgPoint) : nil
        }
        
        dependencies.videoSampler.didCaptureFrame = { [weak self] frame in
            guard let `self` = self else { return }
    
            self.presenter?.present(sampleBuffer: frame)
            
            guard self.isStarted else { return }
            
            self.dependencies.recorder.handleFrame(frame)
            
            guard let capturedImageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(frame) else {
                assertionFailure("Can't create pixel buffer")
                return
            }
            
            self.dependencies.core.setImage(capturedImageBuffer)
            self.dependencies.core.setCameraWidth(
                Float(CVPixelBufferGetWidth(capturedImageBuffer)),
                height: Float(CVPixelBufferGetHeight(capturedImageBuffer)),
                focalLenght: self.dependencies.videoSampler.focalLenght,
                fieldOfView: self.dependencies.videoSampler.fieldOfView
            )
        }
        
        sessionManager.listener = self
    
        subscribeToNotifications()
    }
    
    deinit {
        unsubscribeFromNotifications()
        dependencies.broadcasting.stop()
        enableSyncObservation?.invalidate()
        syncOverCellularObservation?.invalidate()
    }
    
    private func updateSegmentationPerformance(_ performance: ModelPerformance) {
        switch ModelPerformanceResolver.coreModelPerformance(for: .segmentation, with: performance) {
        case .fixed(let fps):
            dependencies.core.config.setSegmentationFixedFPS(fps)
        case .dynamic(let minFps, let maxFps):
            dependencies.core.config.setSegmentationDynamicFPS(minFPS: minFps, maxFPS: maxFps)
        }
    }
    
    private func updateDetectionPerformance(_ performance: ModelPerformance) {
        switch ModelPerformanceResolver.coreModelPerformance(for: .detection, with: performance) {
        case .fixed(let fps):
            dependencies.core.config.setDetectionFixedFPS(fps)
        case .dynamic(let minFps, let maxFps):
            dependencies.core.config.setDetectionDynamicFPS(minFPS: minFps, maxFPS: maxFps)
        }
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
            guard let `self` = self, self.isStoppedForBackground else { return }
            self.isStoppedForBackground = false
            self.start()
        })
    
        notificationObservers.append(center.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: .main) { [weak self] _ in
            guard let `self` = self, self.isStarted else { return }
            self.isStoppedForBackground = true
            self.stop()
        })
    }
    
    private func unsubscribeFromNotifications() {
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
    }
    
    private func startSync() {
        guard isSyncAllowed else {
            hasPendingSyncRequest = false
            return
        }
        
        if isSyncing {
            hasPendingSyncRequest = true
        } else {
            hasPendingSyncRequest = false
            dependencies.recordSynchronizer.sync()
        }
    }
    
    private func stopSync() {
        dependencies.recordSynchronizer.stopSync()
    }
    
    private func setDataProvider(_ dataProvider: DataProvider) {
        let isActivated = self.isStarted
        
        stop()
        
        self.dataProvider = dataProvider
        dependencies.core.restart()
        
        if isActivated {
            start()
        }
    }
    
    private func setRecording(at path: RecordingPath, startTime: UInt) {
        currentRecording = path
        
        let recordedDataProvider = RecordedDataProvider(dependencies: RecordedDataProvider.Dependencies(
            core: dependencies.core,
            recordingPath: path,
            startTime: startTime
        ))
        
        DispatchQueue.main.async { [weak self] in
            self?.setDataProvider(recordedDataProvider)
        }
    }
}

extension VisionManager: ARDataProvider {
    /**
        Device parameters
    */
    public func getCameraParams() -> ARCameraParameters {
        return dependencies.core.getARCameraParams()
    }
    /**
        AR Qubic spline of route
    */
    public func getARRouteData() -> ARRouteData {
        return dependencies.core.getARRouteData()
    }
}

extension VisionManager: SyncDelegate {
    func syncStarted() {
        backgroundTask = UIApplication.shared.beginBackgroundTask()
        isSyncing = true
    }
    
    func syncStopped() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        isSyncing = false
    }
}

extension VisionManager: VideoStreamInteractable {
    func toggleDebugOverlay() {
        dependencies.core.config.useDebugOverlay = !dependencies.core.config.useDebugOverlay
    }
    
    func toggleSegmentationOverlay() {
        dependencies.core.config.drawSegMaskInDebug = !dependencies.core.config.drawSegMaskInDebug
    }
    
    func clearCache(force: Bool) {
        guard force else {
            presenter?.showClearCacheAlert()
            return
        }
        
        dependencies.recorder.stopRecording()
        dependencies.recorder.clearCache()
    }
    
    func selectRecording(at url: URL) {
        let showPath = url.lastPathComponent
        guard let recordingPath = RecordingPath(showPath: showPath, settings: dependencies.videoSettings) else { return }
        setRecording(at: recordingPath, startTime: 0)
    }
    
    func startBroadcasting(at timestamp: String) {
        guard
            let showPath = ShowcaseRecordDataSource().recordDirectories.first,
            let path = RecordingPath(
                showPath: showPath.lastPathComponent,
                settings: dependencies.videoSettings
            )
            else { return }
        
        let startTime = ms(from: timestamp)
        setRecording(at: path, startTime: startTime)
    }
    
    var core: Core {
        return dependencies.core
    }
}

extension VisionManager: RecordCoordinatorDelegate {
    func recordingStarted(path: String) {
        dependencies.core.startSession(path)
    }
    
    func recordingStopped() {
        startSync()
        
        if hasPendingRecordingRequest {
            hasPendingRecordingRequest = false
            try? dependencies.recorder.startRecording(referenceTime: dependencies.core.getSeconds())
        }
    }
}

extension VisionManager: SessionDelegate {
    func sessionStarted() {
        do {
            try dependencies.recorder.startRecording(referenceTime: dependencies.core.getSeconds())
        } catch RecordCoordinatorError.cantStartNotReady {
            hasPendingRecordingRequest = true
        } catch {
            print(error)
        }
    }
    
    func sessionStopped() {
        dependencies.core.stopSession()
        dependencies.recorder.stopRecording()
    }
}

extension VisionManager: MetaInfoObserver {
    func location(_ location: CLLocation) {
        output?.locationUpdated(location)
    }
    
    func heading(_ heading: CLHeading) {}
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

private func ms(from timestamp: String) -> UInt {
    let components = timestamp.components(separatedBy: CharacterSet([":", "."]))
    
    guard
        components.count == 4,
        let h = UInt(components[0]),
        let m = UInt(components[1]),
        let s = UInt(components[2]),
        let ms = UInt(components[3])
        else { return 0 }
    
    let value = (h * 3600000) + (m * 60000) + (s * 1000) + ms
    return value
}
