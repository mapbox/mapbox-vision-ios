import Foundation
import MapboxVisionNative

protocol VisionManagerBaseNativeProtocol: AnyObject {
    var config: CoreConfig { get set }
    var delegate: VisionDelegate? { get set }
    var videoSource: MBVVideoSource? { get set }

    func pixel(toWorld screenCoordinate: Point2D) -> WorldCoordinate?
    func world(toPixel worldCoordinate: WorldCoordinate) -> Point2D?
    func geo(toWorld geoCoordinate: GeoCoordinate) -> WorldCoordinate?
    func world(toGeo worldCoordinates: WorldCoordinate) -> GeoCoordinate?

    func setFixedFPS(_ fps: Float)
    func setDynamicFPS(minFPS: Float, maxFPS: Float)
}

protocol VisionManagerNativeProtocol: VisionManagerBaseNativeProtocol {
    var sensors: SensorsInterface { get }

    func start()
    func stop()

    func destroy()

    func startRecording(to path: String)
    func stopRecording()
}

extension VisionManagerBaseNative: VisionManagerBaseNativeProtocol {}

extension VisionManagerNative: VisionManagerNativeProtocol {}
