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
     Converts the location of the point from a screen coordinate to a world coordinate.

     - Parameter screenCoordinate: Screen coordinate expressed in pixels
     - Returns: World coordinate if `screenCoordinate` can be projected on the road and nil otherwise
     */
    func pixelToWorld(screenCoordinate: Point2D) -> WorldCoordinate?

    /**
     Converts the location of the point from a world coordinate to a screen coordinate.

     - Parameter worldCoordinate: Point in world coordinate
     - Returns: Screen coordinate if `worldCoordinate` can be represented in screen coordinates and nil otherwise
     */
    func worldToPixel(worldCoordinate: WorldCoordinate) -> Point2D?

    /**
     Converts the location of the point from a geographical coordinate to a world coordinate.

     - Parameter geoCoordinate: Geographical coordinate of the point
     - Returns: World coordinate if `geoCoordinate` can be represented in world coordinates and nil otherwise
     */
    func geoToWorld(geoCoordinate: GeoCoordinate) -> WorldCoordinate?

    /**
     Converts the location of the point in a world coordinate to a geographical coordinate.

     - Parameter worldCoordinate: World coordinate of the point
     - Returns: Geographical coordinate if `worldCoordinate` can be represented in geographical coordinates and nil otherwise
     */
    func worldToGeo(worldCoordinates: WorldCoordinate) -> GeoCoordinate?

    /// :nodoc:
    var native: VisionManagerBaseNative { get }
}
