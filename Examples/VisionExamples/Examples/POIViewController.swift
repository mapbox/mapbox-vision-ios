import MapboxVision
import UIKit

/**
 * "POI drawing" example demonstrates how to draw a point of interest on the screen knowing its geogaphical coordinates
 * and using coordinate transformation functions.
 */

// POI coordinates for a provided session. Use your own for real-time or other recorded sessions
private let carWashCoordinate = GeoCoordinate(lon: 27.689583, lat: 53.945542)
private let gasStationCoordinate = GeoCoordinate(lon: 27.689583, lat: 53.945542)

private let distanceVisibilityThreshold = 150.0
private let distanceAboveGround = 10.0
private let poiDimension = 5.0

class POIViewController: UIViewController {
    // used only in real-time session
    private var cameraVideoSource: CameraVideoSource?
    // change type to VisionManager for real-time session
    private var visionManager: VisionReplayManager!

    private let visionViewController = VisionPresentationViewController()
    private var carWashView: UIView!
    private var gasStationView: UIView!

    // latest value of a camera
    private var camera: Camera?

    override func viewDidLoad() {
        super.viewDidLoad()

        // set up views
        addVisionView()
        addPOIViews()

        /** Use this section for real-time events
         // create a video source obtaining buffers from camera module
         cameraVideoSource = CameraVideoSource()
         // create VisionManager with video source
         visionManager = VisionManager.create(videoSource: cameraVideoSource!)
         */

        /// ** Use this section for recorded sessions
        // Path representing Documents directory where files uploaded via Finder appear
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let path = documentsPath.appending("/default")

        // create VisionReplayManager with a path to recorded session
        visionManager = try? VisionReplayManager.create(recordPath: path)
        // */

        visionManager.delegate = self

        // configure view to display sample buffers from video source
        visionViewController.set(visionManager: visionManager)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        visionManager.start()
        cameraVideoSource?.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        cameraVideoSource?.stop()
        visionManager.stop()
    }

    private func addVisionView() {
        addChild(visionViewController)
        view.addSubview(visionViewController.view)
        visionViewController.didMove(toParent: self)
    }

    private func addPOIViews() {
        gasStationView = UIImageView(image: UIImage(named: "alert"))
        gasStationView.isHidden = true
        view.addSubview(gasStationView)

        carWashView = UIImageView(image: UIImage(named: "alert"))
        carWashView.isHidden = true
        view.addSubview(carWashView)
    }

    deinit {
        // free up VisionManager's resources, should be called after destroing its module
        visionManager.destroy()
    }

    private func updatePOI(visionManager: VisionManagerProtocol, geoCoordinate: GeoCoordinate, poiView: UIView) {
        // hide the view if one of conditions isn't met
        let hideView = {
            poiView.isHidden = true
        }

        guard
            // convert geo to world
            let poiWorldCoordinate = visionManager.geoToWorld(geoCoordinate: geoCoordinate),
            // make sure POI is in front of the camera and not too far away
            poiWorldCoordinate.x > 0, poiWorldCoordinate.x < distanceVisibilityThreshold
        else {
            hideView()
            return
        }

        // by default height of the translated geo coordinate is 0.
        // If you'd like to lift it above the ground alter its `z` coordinate
        let worldCoordinateLeftTop     = WorldCoordinate(x: poiWorldCoordinate.x,
                                                         y: poiWorldCoordinate.y - poiDimension / 2,
                                                         z: distanceAboveGround + poiDimension / 2)
        let worldCoordinateRightBottom = WorldCoordinate(x: poiWorldCoordinate.x,
                                                         y: poiWorldCoordinate.y + poiDimension / 2,
                                                         z: distanceAboveGround - poiDimension / 2)

        guard
            // convert the POI to the screen coordinates
            let screenCoordinateLeftTop = visionManager.worldToPixel(worldCoordinate: worldCoordinateLeftTop),
            let screenCoordinateRightBottom = visionManager.worldToPixel(worldCoordinate: worldCoordinateRightBottom)
        else {
            hideView()
            return
        }

        guard let frameSize = camera?.frameSize.cgSize else {
            hideView()
            return
        }

        let viewSize = view.bounds.size

        let leftTop = screenCoordinateLeftTop.cgPoint.convertForAspectRatioFill(from: frameSize, to: viewSize)
        let rightBottom = screenCoordinateRightBottom.cgPoint.convertForAspectRatioFill(from: frameSize, to: viewSize)

        let poiFrame = CGRect(x: leftTop.x,
                              y: leftTop.y,
                              width: rightBottom.x - leftTop.x,
                              height: rightBottom.y - leftTop.y)

        poiView.frame = poiFrame
        poiView.isHidden = false
    }
}

extension POIViewController: VisionManagerDelegate {
    func visionManager(_: VisionManagerProtocol, didUpdateCamera camera: Camera) {
        // dispatch to the main queue in order to sync access to `Camera` instance
        DispatchQueue.main.async {
            self.camera = camera
            print("Calibration: \(camera.calibrationProgress)")
        }
    }

    func visionManagerDidCompleteUpdate(_ visionManager: VisionManagerProtocol) {
        // dispatch to the main queue in order to work with UIKit elements and sync access to `Camera` instance
        DispatchQueue.main.async {
            self.updatePOI(visionManager: visionManager, geoCoordinate: gasStationCoordinate, poiView: self.gasStationView)
            self.updatePOI(visionManager: visionManager, geoCoordinate: carWashCoordinate, poiView: self.carWashView)
        }
    }
}
