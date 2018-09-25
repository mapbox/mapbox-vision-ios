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
        Tells the delegate that new road description is available.
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
    var videoVisualizationMode: VisualizationMode { get set }
    
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
private let sessionInterval: TimeInterval = 5 * 60
private let dataRecordingSessionInterval: TimeInterval = 30 * 60

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
    var videoVisualizationMode: VisualizationMode = .clear {
        didSet {
            let config: CoreConfig
            switch videoVisualizationMode {
            case .segmentation: config = CoreConfig.segmentationFirst
            case .detection: config = CoreConfig.detectionFirst
            case .clear: config = CoreConfig.basic
            }
            self.dependencies.core.config = config
            presenter?.present(visualizationMode: videoVisualizationMode)
        }
    }
    
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
    
        let interval = isDataRecordingModeOn ? dataRecordingSessionInterval : sessionInterval
        sessionManager.startSession(interruptionInterval: interval)
    
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
    
    public var segmentationPerformance: ModelPerformance = ModelPerformance(mode: .dynamic, rate: .high) {
        didSet {
            switch ModelPerformanceResolver.coreModelPerformance(for: .segmentation, with: segmentationPerformance) {
            case .fixed(let fps):
                dependencies.core.config.setSegmentationFixedFPS(fps)
            case .dynamic(let minFps, let maxFps):
                dependencies.core.config.setSegmentationDynamicFPS(minFPS: minFps, maxFPS: maxFps)
            }
        }
    }
    
    /**
        Used for configuration of detection-related tasks performance.
    */
    
    public var detectionPerformance: ModelPerformance = ModelPerformance(mode: .dynamic, rate: .high) {
        didSet {
            switch ModelPerformanceResolver.coreModelPerformance(for: .detection, with: detectionPerformance) {
            case .fixed(let fps):
                dependencies.core.config.setDetectionFixedFPS(fps)
            case .dynamic(let minFps, let maxFps):
                dependencies.core.config.setDetectionDynamicFPS(minFPS: minFps, maxFPS: maxFps)
            }
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
        :nodoc:
    */

    public var isDataRecordingModeOn: Bool = false {
        didSet {
            guard isDataRecordingModeOn != oldValue else { return }
            
            dependencies.core.config.useSegmentation = !isDataRecordingModeOn
            dependencies.core.config.useDetection = !isDataRecordingModeOn
            
            dependencies.recorder.savesContinuousVideo = isDataRecordingModeOn
            
            UserDefaults.standard.enableSync = !isDataRecordingModeOn
        }
    }
    
    /**
        :nodoc:
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
            
            self.roadDescription = self.dependencies.core.getRoadDescription()
            
            self.worldDescription = self.dependencies.core.getWorldDescription()
            
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
    
    private func registerDefaults() {
        let defaults = UserDefaults.standard
        defaults.setDefaultValue(true, forKey: VisionSettings.enableSync)
        defaults.setDefaultValue(false, forKey: VisionSettings.syncOverCellular)
    }
    
    private func subscribeToNotifications() {
        let center = NotificationCenter.default
        notificationObservers.append(center.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: .main) { [weak self] _ in
            self?.start()
        })
    
        notificationObservers.append(center.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: .main) { [weak self] _ in
            self?.stop()
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
        if force {
            let isCurrentlyRecording = dependencies.recorder.isRecording
            if isCurrentlyRecording {
                dependencies.recorder.stopRecording()
            }
            dependencies.recorder.clearCache()
            if isCurrentlyRecording {
                dependencies.recorder.startRecording(referenceTime: dependencies.core.getSeconds())
            }
            return
        }
        presenter?.showClearCacheAlert()
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
        if hasPendingRecordingRequest, dependencies.recorder.isReady {
            hasPendingRecordingRequest = false
            dependencies.recorder.startRecording(referenceTime: dependencies.core.getSeconds())
        }
    }
}

extension VisionManager: SessionDelegate {
    func sessionStarted() {
        if dependencies.recorder.isReady {
            dependencies.recorder.startRecording(referenceTime: dependencies.core.getSeconds())
        } else {
            hasPendingRecordingRequest = true
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
