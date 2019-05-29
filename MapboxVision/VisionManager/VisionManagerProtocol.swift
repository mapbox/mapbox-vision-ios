import Foundation

/**
 Protocol that provides an ability to use `VisionManager` and `VisionReplayManager` interchangeably by abstracting common functionality.
 */
public protocol VisionManagerProtocol: AnyObject {
    /**
     Performance configuration for machine learning models.
     Default value is merged with dynamic performance mode and high rate.
     */
    var modelPerformanceConfig: ModelPerformanceConfig { get set }

    /**
     Converts location of the point from a screen coordinate to a world coordinate.

     - Parameter screenCoordinate: Screen coordinate expressed in pixels
     */
    func pixelToWorld(screenCoordinate: Point2D) -> WorldCoordinate

    /**
     Converts location of the point from a world coordinate to a screen coordinate.

     - Parameter worldCoordinate: Point in world coordinate
     */
    func worldToPixel(worldCoordinate: WorldCoordinate) -> Point2D

    /**
     Converts location of the point from a geo coordinate to a world coordinate.

     - Parameter geoCoordinate: Geographical coordinate of the point
     */
    func geoToWorld(geoCoordinate: GeoCoordinate) -> WorldCoordinate

    /**
     Converts location of the point in a world coordinate to a geographical coordinate.

     - Parameter worldCoordinate: World coordinate of the point
     */
    func worldToGeo(worldCoordinates: WorldCoordinate) -> GeoCoordinate

    /// :nodoc:
    var native: VisionManagerBaseNative { get }
}
