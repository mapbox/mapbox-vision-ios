final class RealtimeDataProvider {

    struct Dependencies {
        let native: VisionManagerNative
        let motionManager: MotionManager
        let locationManager: LocationManager
    }

    // MARK: - Private properties

    private let dependencies: Dependencies

    // MARK: - Lifecycle

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        dependencies.motionManager.handler = dependencies.native.sensors.setDeviceMotion
        dependencies.locationManager.locationHandler = dependencies.native.sensors.setGPS
        dependencies.locationManager.headingHandler = dependencies.native.sensors.setHeading
    }
}

extension RealtimeDataProvider: DataProvider {
    func start() {
        dependencies.locationManager.start()
        dependencies.motionManager.start(updateInterval: Constants.motionUpdateInterval)
    }

    func update() {}

    func stop() {
        dependencies.locationManager.stop()
        dependencies.motionManager.stop()
    }
}
