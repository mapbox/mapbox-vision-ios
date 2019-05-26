import Foundation

public class BaseVisionManager {

    // MARK: - Properties

    var delegate: VisionManagerDelegate? // TODO: check internal/public properties & marks

    public var native: VisionManagerBaseNative {
        return dependencies.native
    }

    // MARK: Performance control

    public var modelPerformanceConfig: ModelPerformanceConfig =
        .merged(performance: ModelPerformance(mode: .dynamic, rate: .high)) {
        didSet {
            guard oldValue != modelPerformanceConfig else { return }
            updateModelPerformanceConfig(modelPerformanceConfig)
        }
    }

    // MARK - Private properties

    private(set) var currentCountry = Country.unknown

    private(set) var dependencies: BaseDependencies
    private var isStoppedForBackground = false
    private var notificationObservers = [Any]()

    private var isSyncAllowed: Bool {
        switch currentCountry {
        case .unknown, .china: return false
        case .UK, .USA, .other: return true
        }
    }

    // MARK: - Lifecycle

    init(dependencies: BaseDependencies) {
        self.dependencies = dependencies

        dependencies.native.config = .basic
        updateModelPerformanceConfig(modelPerformanceConfig)
        subscribeToNotifications()
    }

    deinit {
        unsubscribeFromNotifications()
    }

    // MARK: - Internal functions

    func prepareForForeground() {}

    func prepareForBackground() {}

    func trySync() {
        if isSyncAllowed {
            dependencies.synchronizer.sync()
        }
    }

    // MARK: - Private functions

    // MARK: Model performance configuration

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

    // MARK: Notifications

    private func subscribeToNotifications() {
        let center = NotificationCenter.default
        notificationObservers.append(center.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                                        object: nil,
                                                        queue: .main) { [weak self] _ in
            self?.prepareForForeground()
        })

        notificationObservers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                        object: nil,
                                                        queue: .main) { [weak self] _ in
            self?.prepareForBackground()
        })
    }

    private func unsubscribeFromNotifications() {
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
    }

    // MARK: Utility

    private func configureSync(_ country: Country) {
        switch country {
        case .UK, .USA, .other:
            dependencies.synchronizer.sync()
        case .china:
            dependencies.synchronizer.stopSync()
            let data = SyncRecordDataSource()
            data.recordDirectories.forEach(data.removeFile)
        case .unknown:
            dependencies.synchronizer.stopSync()
        }
    }
}

extension BaseVisionManager: VisionDelegate {
    public func onAuthorizationStatusUpdated(_ status: AuthorizationStatus) {
        delegate?.visionManager(self, didUpdateAuthorizationStatus: status)
    }

    public func onFrameSegmentationUpdated(_ segmentation: FrameSegmentation) {
        delegate?.visionManager(self, didUpdateFrameSegmentation: segmentation)
    }

    public func onFrameDetectionsUpdated(_ detections: FrameDetections) {
        delegate?.visionManager(self, didUpdateFrameDetections: detections)
    }

    public func onFrameSignClassificationsUpdated(_ signClassifications: FrameSignClassifications) {
        delegate?.visionManager(self, didUpdateFrameSignClassifications: signClassifications)
    }

    public func onRoadDescriptionUpdated(_ road: RoadDescription) {
        delegate?.visionManager(self, didUpdateRoadDescription: road)
    }

    public func onWorldDescriptionUpdated(_ world: WorldDescription) {
        delegate?.visionManager(self, didUpdateWorldDescription: world)
    }

    public func onVehicleStateUpdated(_ vehicleState: VehicleState) {
        delegate?.visionManager(self, didUpdateVehicleState: vehicleState)
    }

    public func onCameraUpdated(_ camera: Camera) {
        delegate?.visionManager(self, didUpdateCamera: camera)
    }

    public func onCountryUpdated(_ country: Country) {
        currentCountry = country
        delegate?.visionManager(self, didUpdateCountry: country)
        configureSync(country)
    }

    public func onUpdateCompleted() {
        delegate?.visionManagerDidCompleteUpdate(self)
    }
}
