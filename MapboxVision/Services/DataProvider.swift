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
    }

    func start() {
        dependencies.locationManager.locationHandler = dependencies.native.sensors.setGPS
        dependencies.locationManager.headingHandler = dependencies.native.sensors.setHeading
        dependencies.locationManager.start()

        dependencies.motionManager.handler = dependencies.native.sensors.setDeviceMotion
        dependencies.motionManager.start(updateInterval: Constants.motionUpdateInterval)
    }

    func update() {}

    func stop() {
        dependencies.locationManager.stop()
        dependencies.locationManager.locationHandler = nil
        dependencies.locationManager.headingHandler = nil

        dependencies.motionManager.stop()
        dependencies.motionManager.handler = nil
    }
}
