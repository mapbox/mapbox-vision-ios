@testable import MapboxVision
@testable import MapboxVisionNative

class MockNative: VisionManagerNativeProtocol {
    weak var delegate: VisionDelegate?

    var videoSource: MBVVideoSource?

    private(set) var isDestroyed: Bool = false

    var config = CoreConfig()

    var sensors: SensorsInterface {
        return MockSensors()
    }

    func start() {}

    func stop() {}

    func startRecording(to path: String) {}

    func stopRecording() {}

    func destroy() {
        isDestroyed = true
    }

    func pixel(toWorld screenCoordinate: Point2D) -> WorldCoordinate? {
        return nil
    }

    func world(toPixel worldCoordinate: WorldCoordinate) -> Point2D? {
        return nil
    }

    func geo(toWorld geoCoordinate: GeoCoordinate) -> WorldCoordinate? {
        return nil
    }

    func world(toGeo worldCoordinates: WorldCoordinate) -> GeoCoordinate? {
        return nil
    }

    func setFixedFPS(_ fps: Float) {}

    func setDynamicFPS(minFPS: Float, maxFPS: Float) {}

    func set(cameraHeight: Float) {}
}
