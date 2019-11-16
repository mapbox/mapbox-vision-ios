import Foundation
import MapboxVisionNative

protocol DataProvider: AnyObject {
    func start()
    func update()
    func stop()
}

final class RealtimeDataProvider: DataProvider {
    struct Dependencies {
        let native: VisionManagerNative
        let motionManager: MotionManager
        let locationManager: LocationManager
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        dependencies.motionManager.handler = dependencies.native.sensors.setDeviceMotion
        dependencies.locationManager.locationHandler = dependencies.native.sensors.setGPS
        dependencies.locationManager.headingHandler = dependencies.native.sensors.setHeading
    }

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
