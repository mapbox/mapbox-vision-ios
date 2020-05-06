import MapboxVision
import MapboxVisionAR
import MapboxVisionSafety

class GettingStartedViewController: UIViewController {
    private var videoSource: CameraVideoSource!

    private var visionManager: VisionManager!
    private var visionARManager: VisionARManager!
    private var visionSafetyManager: VisionSafetyManager!

    private let visionViewController = VisionPresentationViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // create a video source obtaining buffers from camera module
        videoSource = CameraVideoSource()

        // create VisionManager with video source
        visionManager = VisionManager.create(videoSource: videoSource)
        // set up the `VisionManagerDelegate`
        visionManager.delegate = self

        // create VisionARManager to use AR features
        visionARManager = VisionARManager.create(visionManager: visionManager)
        // set up the `VisionARManagerDelegate`
        visionARManager.delegate = self

        // create VisionSafetyManager to use Safety features
        visionSafetyManager = VisionSafetyManager.create(visionManager: visionManager)
        // set up the `VisionSafetyManagerDelegate`
        visionSafetyManager.delegate = self

        // configure view to display sample buffers from video source
        visionViewController.set(visionManager: visionManager)
        addChild(visionViewController)
        view.addSubview(visionViewController.view)
        visionViewController.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // start delivering events
        videoSource.start()
        visionManager.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // stop delivering events
        videoSource.stop()
        visionManager.stop()
    }

    deinit {
        // AR and Safety managers should be destroyed before the Vision manager
        visionARManager.destroy()
        visionSafetyManager.destroy()

        // finally destroy the instance of `VisionManager`
        visionManager.destroy()
    }
}

extension GettingStartedViewController: VisionManagerDelegate {
    // implement required methods of the delegate
}

extension GettingStartedViewController: VisionARManagerDelegate {
    // implement required methods of the delegate
}

extension GettingStartedViewController: VisionSafetyManagerDelegate {
    // implement required methods of the delegate
}

// This comment is here to assure the correct rendering of code snippets in a public documentation
