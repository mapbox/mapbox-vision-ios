/**
 This file is used in a public documentation to show basic configuration steps.
 */

// Need to include Vision functionality
import MapboxVision
// Need to include Vision AR functionality
import MapboxVisionAR
// Need to include Vision Safety functionality
import MapboxVisionSafety

class GettingStartedViewController: UIViewController {
    
    // MARK: - Private properties
    
    private var videoSource: CameraVideoSource!
    
    private var visionManager: VisionManager!
    private var visionARManager: VisionARManager!
    private var visionSafetyManager: VisionSafetyManager!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a video source obtaining buffers from camera module
        videoSource = CameraVideoSource()
        
        // create VisionManager with video source
        visionManager = VisionManager.create(videoSource: videoSource)
        // setting up the `VisionSafetyManagerDelegate`
        visionManager.delegate = self
        
        // create VisionARManager if you want to use AR's features
        visionARManager = VisionARManager.create(visionManager: visionManager)
        // setting up the `VisionSafetyManagerDelegate`
        visionARManager.delegate = self
        
        // create VisionSafetyManager if you want to use Safety's features
        visionSafetyManager = VisionSafetyManager.create(visionManager: visionManager)
        // setting up the `VisionSafetyManagerDelegate`
        visionSafetyManager.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start delivering events
        videoSource.start()
        visionManager.start()
        visionARManager.start()
        visionSafetyManager.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Stop delivering events
        videoSource.stop()
        visionManager.stop()
        visionARManager.stop()
        visionSafetyManager.stop()
    }
    
    deinit {
        // AR and/or Safety managers should be destroyed first
        visionARManager.destroy()
        visionSafetyManager.destroy()

        // Finally destroy the instance of `VisionManager`
        visionManager.destroy()
    }
}

extension GettingStartedViewController: VisionManagerDelegate {
    // Put implementation of delegate methods
}

extension GettingStartedViewController: VisionARManagerDelegate {
    // Put implementation of delegate methods
}

extension GettingStartedViewController: VisionSafetyManagerDelegate {
    // Put implementation of delegate methods
}

