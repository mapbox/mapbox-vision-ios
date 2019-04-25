import Foundation
import MapboxDirections
import MapboxVisionARNative

public extension MapboxVisionARNative.Route {
    /**
        Create `MapboxVisionARNative.Route` instance from `MapboxDirections.Route`.
    */
    public convenience init(route: MapboxDirections.Route) {
        var points = [RoutePoint]()

        route.legs.forEach { $0.steps
            .forEach { step in
                let maneuver = RoutePoint(position: GeoCoordinate(lon: step.maneuverLocation.longitude, lat: step.maneuverLocation.latitude))
                points.append(maneuver)

                guard let coords = step.coordinates else { return }
                let routePoints = coords.map {
                    RoutePoint(position: GeoCoordinate(lon: $0.longitude, lat: $0.latitude))
                }
                points.append(contentsOf: routePoints)
            }
        }

        self.init(points: points,
                  eta: Float(route.expectedTravelTime),
                  sourceStreetName: route.legs.first?.source.name ?? "",
                  destinationStreetName: route.legs.last?.destination.name ?? "")
    }
}
