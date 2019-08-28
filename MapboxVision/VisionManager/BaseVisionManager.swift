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

    weak var baseDelegate: VisionManagerDelegate?

    private let dependencies: BaseDependencies
    private var isStoppedForBackground = false
    private var notificationObservers = [Any]()

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

    // MARK: Model performance configuration

    private func updateModelPerformanceConfig(_ config: ModelPerformanceConfig) {
        switch config {
        case let .merged(performance):
            dependencies.native.useMergedModel = true
            update(performance: performance, for: .mergedSegDetect)
        case let .separate(segmentationPerformance, detectionPerformance):
            dependencies.native.useMergedModel = false
            update(performance: segmentationPerformance, for: .segmentation)
            update(performance: detectionPerformance, for: .detection)
        }
    }

    private func update(performance: ModelPerformance, for modelType: MLModelType) {
        switch ModelPerformanceResolver.coreModelPerformance(for: modelType, with: performance) {
        case .fixed(let fps):
            dependencies.native.setFixedFPS(for: modelType, FPS: fps)
        case .dynamic(let minFps, let maxFps):
            dependencies.native.setDynamicFPS(for: modelType, minFPS: minFps, maxFPS: maxFps)
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
}

extension BaseVisionManager: VisionDelegate {
    public func onAuthorizationStatusUpdated(_ status: AuthorizationStatus) {
        baseDelegate?.visionManager(self, didUpdateAuthorizationStatus: status)
    }

    public func onFrameSegmentationUpdated(_ segmentation: FrameSegmentation) {
        baseDelegate?.visionManager(self, didUpdateFrameSegmentation: segmentation)
    }

    public func onFrameDetectionsUpdated(_ detections: FrameDetections) {
        baseDelegate?.visionManager(self, didUpdateFrameDetections: detections)
    }

    public func onFrameSignClassificationsUpdated(_ signClassifications: FrameSignClassifications) {
        baseDelegate?.visionManager(self, didUpdateFrameSignClassifications: signClassifications)
    }

    public func onRoadDescriptionUpdated(_ road: RoadDescription) {
        baseDelegate?.visionManager(self, didUpdateRoadDescription: road)
    }

    public func onWorldDescriptionUpdated(_ world: WorldDescription) {
        baseDelegate?.visionManager(self, didUpdateWorldDescription: world)
    }

    public func onVehicleStateUpdated(_ vehicleState: VehicleState) {
        baseDelegate?.visionManager(self, didUpdateVehicleState: vehicleState)
    }

    public func onCameraUpdated(_ camera: Camera) {
        baseDelegate?.visionManager(self, didUpdateCamera: camera)
    }

    public func onCountryUpdated(_ country: Country) {
        baseDelegate?.visionManager(self, didUpdateCountry: country)
    }

    public func onUpdateCompleted() {
        baseDelegate?.visionManagerDidCompleteUpdate(self)
    }
}
