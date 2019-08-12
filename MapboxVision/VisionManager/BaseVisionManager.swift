import Foundation

public class BaseVisionManager: VisionManagerProtocol {
    // MARK: Performance control

    public var modelPerformanceConfig: ModelPerformanceConfig =
        .merged(performance: ModelPerformance(mode: .dynamic, rate: .high)) {
            didSet {
                guard oldValue != modelPerformanceConfig else { return }
                updateModelPerformanceConfig(modelPerformanceConfig)
            }
        }

    // MARK: Utility

    public func pixelToWorld(screenCoordinate: Point2D) -> WorldCoordinate? {
        return dependencies.native.pixel(toWorld: screenCoordinate)
    }

    public func worldToPixel(worldCoordinate: WorldCoordinate) -> Point2D? {
        return dependencies.native.world(toPixel: worldCoordinate)
    }

    public func geoToWorld(geoCoordinate: GeoCoordinate) -> WorldCoordinate? {
        return dependencies.native.geo(toWorld: geoCoordinate)
    }

    public func worldToGeo(worldCoordinates: WorldCoordinate) -> GeoCoordinate? {
        return dependencies.native.world(toGeo: worldCoordinates)
    }

    public var native: VisionManagerBaseNative {
        return dependencies.native as! VisionManagerBaseNative
    }

    weak var delegate: VisionManagerDelegate?
    private(set) var currentCountry = Country.unknown

    private let dependencies: BaseDependencies
    private var isStoppedForBackground = false
    private var notificationObservers = [Any]()

    private var isSyncAllowed: Bool {
        switch currentCountry {
        case .unknown, .china: return false
        case .UK, .USA, .other: return true
        }
    }

    // MARK: Initialization

    init(dependencies: BaseDependencies) {
        self.dependencies = dependencies

        dependencies.native.config = .basic
        updateModelPerformanceConfig(modelPerformanceConfig)
        subscribeToNotifications()
    }

    deinit {
        unsubscribeFromNotifications()
    }

    // MARK: Internal

    func prepareForForeground() {}

    func prepareForBackground() {}

    func trySync() {
        if isSyncAllowed {
            dependencies.synchronizer.sync()
        }
    }

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
            dependencies.native.setSegmentationFixedFPS(fps)
        case .dynamic(let minFps, let maxFps):
            dependencies.native.setSegmentationDynamicFPS(minFPS: minFps, maxFPS: maxFps)
        }
    }

    private func updateDetectionPerformance(_ performance: ModelPerformance) {
        switch ModelPerformanceResolver.coreModelPerformance(for: .detection, with: performance) {
        case .fixed(let fps):
            dependencies.native.setDetectionFixedFPS(fps)
        case .dynamic(let minFps, let maxFps):
            dependencies.native.setDetectionDynamicFPS(minFPS: minFps, maxFPS: maxFps)
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

    // MARK: Private

    private func configureSync(oldCountry: Country, newCountry: Country) {
        if newCountry.syncRegion == nil {
            dependencies.synchronizer.stopSync()
            return
        }

        guard
            let newRegion = newCountry.syncRegion,
            oldCountry.syncRegion != newRegion
        else { return }

        let dataSource = SyncRecordDataSource(region: newRegion)
        dependencies.synchronizer.stopSync()
        dependencies.synchronizer.set(dataSource: dataSource)
        dependencies.synchronizer.sync()
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
        let oldCountry = currentCountry
        currentCountry = country
        configureSync(oldCountry: oldCountry, newCountry: country)
        delegate?.visionManager(self, didUpdateCountry: country)
    }

    public func onUpdateCompleted() {
        delegate?.visionManagerDidCompleteUpdate(self)
    }
}
