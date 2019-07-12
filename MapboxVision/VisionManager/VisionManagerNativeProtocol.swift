import Foundation
import MapboxVisionNative

protocol VisionManagerBaseNativeProtocol: AnyObject {
    var config: CoreConfig { get set }

    func pixel(toWorld screenCoordinate: Point2D) -> WorldCoordinate?
    func world(toPixel worldCoordinate: WorldCoordinate) -> Point2D?
    func geo(toWorld geoCoordinate: GeoCoordinate) -> WorldCoordinate?
    func world(toGeo worldCoordinates: WorldCoordinate) -> GeoCoordinate?

    func setSegmentationFixedFPS(_: Float)
    func setSegmentationDynamicFPS(minFPS: Float, maxFPS: Float)
    func setDetectionFixedFPS(_: Float)
    func setDetectionDynamicFPS(minFPS: Float, maxFPS: Float)
}

protocol VisionManagerNativeProtocol: VisionManagerBaseNativeProtocol {
    var sensors: SensorsInterface { get }

    func start(_: VisionDelegate)
    func stop()

    func destroy()

    func getSeconds() -> Float
    func startSavingSession(_ path: String)
    func stopSavingSession()
}

extension VisionManagerBaseNative: VisionManagerBaseNativeProtocol {
}

extension VisionManagerNative: VisionManagerNativeProtocol {
}
