extension BaseVisionManager: VisionManagerProtocol {
    public func pixelToWorld(screenCoordinate: Point2D) -> WorldCoordinate {
        return dependencies.native.pixel(toWorld: screenCoordinate)
    }

    public func worldToPixel(worldCoordinate: WorldCoordinate) -> Point2D {
        return dependencies.native.world(toPixel: worldCoordinate)
    }

    public func geoToWorld(geoCoordinate: GeoCoordinate) -> WorldCoordinate {
        return dependencies.native.geo(toWorld: geoCoordinate)
    }

    public func worldToGeo(worldCoordinates: WorldCoordinate) -> GeoCoordinate {
        return dependencies.native.world(toGeo: worldCoordinates)
    }
}
