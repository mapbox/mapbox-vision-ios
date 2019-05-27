import MapboxVision
import MapboxVisionAR
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
        videoSource.add(observer: self)

        // create VisionManager with video source
        visionManager = VisionManager.create(videoSource: videoSource)
        // create VisionARManager and register as its delegate to receive AR related events
        visionARManager = VisionARManager.create(visionManager: visionManager, delegate: self)

        let origin = CLLocationCoordinate2D()
        let destination = CLLocationCoordinate2D()
        let options = NavigationRouteOptions(coordinates: [origin, destination], profileIdentifier: .automobile)

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
        // free up resources by destroying modules when they're not longer used
        visionARManager.destroy()
    }

    private func addARView() {
        addChild(visionARViewController)
        view.addSubview(visionARViewController.view)
        visionARViewController.didMove(toParent: self)
    }
}

extension ARNavigationViewController: VisionARManagerDelegate {
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARCamera camera: ARCamera) {
        DispatchQueue.main.async { [weak self] in
            // pass the camera parameters for projection calculation
            self?.visionARViewController.present(camera: camera)
        }
    }

    func visionARManager(_ visionARManager: VisionARManager, didUpdateARLane lane: ARLane?) {
        DispatchQueue.main.async { [weak self] in
            // display AR lane representing navigation route
            self?.visionARViewController.present(lane: lane)
        }
    }
}

extension ARNavigationViewController: VideoSourceObserver {
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {
        DispatchQueue.main.async { [weak self] in
            // display received sample buffer by passing it to ar view controller
            self?.visionARViewController.present(sampleBuffer: videoSample.buffer)
        }
    }
}
