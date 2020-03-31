import MapboxVision
import UIKit

/**
 * "POI drawing" example demonstrates how to draw a point of interest on the screen knowing its geographical coordinates
 * and using coordinate transformation functions.
 */

// POI coordinates for a provided session. Use your own for real-time or other recorded sessions
private let carWashCoordinate = GeoCoordinate(lon: 27.675944566726685, lat: 53.94105180084251)
private let gasStationCoordinate = GeoCoordinate(lon: 27.674764394760132, lat: 53.9405971055192)

private let distanceVisibilityThreshold = 300.0
private let distanceAboveGround = 16.0
private let poiDimension = 16.0

class POIDrawingViewController: UIViewController {
    private var visionManager: VisionReplayManager!

    private let visionViewController = VisionPresentationViewController()
    private var carWashView = UIImageView(image: UIImage(named: "car_wash"))
    private var gasStationView = UIImageView(image: UIImage(named: "gas_station"))

    // latest value of a camera
    private var camera: Camera?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Documents directory path with files uploaded via Finder
        let documentsPath =
            NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                .userDomainMask,
                                                true).first!
        let path = documentsPath.appending("/poi-drawing")

        // create VisionReplayManager with a path to recorded session
        visionManager = try? VisionReplayManager.create(recordPath: path)
        // register its delegate
        visionManager.delegate = self

        // configure Vision view to display sample buffers from video source
        visionViewController.set(visionManager: visionManager)
        // add Vision view as a child view
        addVisionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visionManager.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        visionManager.stop()
    }

    deinit {
        // free up VisionManager's resources
        visionManager.destroy()
    }

    private func addVisionView() {
        addChild(visionViewController)
        view.addSubview(visionViewController.view)
        visionViewController.didMove(toParent: self)
    }

    private func updatePOI(geoCoordinate: GeoCoordinate, poiView: UIView) {
        // closure that's used to hide the view if one of conditions isn't met
        let hideView = {
            poiView.removeFromSuperview()
        }

        guard
            // make sure that `Camera` is calibrated for more precise transformations
            let camera = camera, camera.isCalibrated,
            // convert geo to world
            let poiWorldCoordinate = visionManager.geoToWorld(geoCoordinate: geoCoordinate),
            // make sure POI is in front of the camera and not too far away
            poiWorldCoordinate.x > 0, poiWorldCoordinate.x < distanceVisibilityThreshold
        else {
            hideView()
            return
        }

        // by default the translated geo coordinate is placed at 0 height in the world space.
        // If you'd like to lift it above the ground alter its `z` coordinate
        let worldCoordinateLeftTop =
            WorldCoordinate(x: poiWorldCoordinate.x,
                            y: poiWorldCoordinate.y - poiDimension / 2,
                            z: distanceAboveGround + poiDimension / 2)

        let worldCoordinateRightBottom =
            WorldCoordinate(x: poiWorldCoordinate.x,
                            y: poiWorldCoordinate.y + poiDimension / 2,
                            z: distanceAboveGround - poiDimension / 2)

        guard
            // convert the POI to the screen coordinates
            let screenCoordinateLeftTop =
                visionManager.worldToPixel(worldCoordinate: worldCoordinateLeftTop),

            let screenCoordinateRightBottom =
                visionManager.worldToPixel(worldCoordinate: worldCoordinateRightBottom)
        else {
            hideView()
            return
        }

        // translate points from the camera frame space to the view space
        let frameSize = camera.frameSize.cgSize
        let viewSize = view.bounds.size

        let leftTop = screenCoordinateLeftTop.cgPoint
            .convertForAspectRatioFill(from: frameSize, to: viewSize)

        let rightBottom = screenCoordinateRightBottom.cgPoint
            .convertForAspectRatioFill(from: frameSize, to: viewSize)

        // construct and apply POI view frame rectangle
        let poiFrame = CGRect(x: leftTop.x,
                              y: leftTop.y,
                              width: rightBottom.x - leftTop.x,
                              height: rightBottom.y - leftTop.y)

        poiView.frame = poiFrame
        view.addSubview(poiView)
    }
}

extension POIDrawingViewController: VisionManagerDelegate {
    func visionManager(_: VisionManagerProtocol, didUpdateCamera camera: Camera) {
        // dispatch to the main queue in order to sync access to `Camera` instance
        DispatchQueue.main.async {
            self.camera = camera
            // you may track the calibration progress
            print("Calibration: \(camera.calibrationProgress)")
        }
    }

    func visionManagerDidCompleteUpdate(_: VisionManagerProtocol) {
        // dispatch to the main queue in order to work with UIKit elements
        // and sync access to `Camera` instance
        DispatchQueue.main.async {
            self.updatePOI(geoCoordinate: gasStationCoordinate,
                           poiView: self.gasStationView)

            self.updatePOI(geoCoordinate: carWashCoordinate,
                           poiView: self.carWashView)
        }
    }
}
//
