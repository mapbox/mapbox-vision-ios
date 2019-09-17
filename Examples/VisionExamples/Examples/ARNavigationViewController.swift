import CoreLocation
import MapboxDirections
import MapboxVision
import MapboxVisionAR
import MapboxVisionARNative
import UIKit

/**
 * "AR Navigation" example demonstrates how to display navigation route projected on the surface of the road.
 */

class ARNavigationViewController: UIViewController {
    private var videoSource: CameraVideoSource!
    private var visionManager: VisionManager!
    private var visionARManager: VisionARManager!

    private let visionARViewController = VisionARViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        addARView()

        // create a video source obtaining buffers from camera module
        videoSource = CameraVideoSource()

        // create VisionManager with video source
        visionManager = VisionManager.create(videoSource: videoSource)
        // create VisionARManager and register as its delegate to receive AR related events
        visionARManager = VisionARManager.create(visionManager: visionManager)

        visionARViewController.set(arManager: visionARManager)

        let origin = CLLocationCoordinate2D()
        let destination = CLLocationCoordinate2D()
        let options = RouteOptions(coordinates: [origin, destination], profileIdentifier: .automobile)

        // query a navigation route between location coordinates and pass it to VisionARManager
        Directions.shared.calculate(options) { [weak self] _, routes, _ in
            guard let route = routes?.first else { return }
            self?.visionARManager.set(route: Route(route: route))
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        visionManager.start()
        videoSource.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        videoSource.stop()
        visionManager.stop()
    }

    private func addARView() {
        addChild(visionARViewController)
        view.addSubview(visionARViewController.view)
        visionARViewController.didMove(toParent: self)
    }

    deinit {
        // free up resources by destroying modules when they're not longer used
        visionARManager.destroy()
        // free up VisionManager's resources, should be called after destroing its module
        visionManager.destroy()
    }
}

extension MapboxVisionARNative.Route {
    /**
     Create `MapboxVisionARNative.Route` instance from `MapboxDirections.Route`.
     */
    convenience init(route: MapboxDirections.Route) {
        var points = [RoutePoint]()

        route.legs.forEach {
            $0.steps.forEach { step in
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
