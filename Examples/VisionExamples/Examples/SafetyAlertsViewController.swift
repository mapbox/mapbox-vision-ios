import MapboxVision
import MapboxVisionSafety
import UIKit

/**
 * "Safety alerts" example demonstrates how to utilize events from MapboxVisionSafetyManager
 * to alert a user about exceeding allowed speed limit and potential collisions with other cars.
 */

class SafetyAlertsViewController: UIViewController {
    private var visionManager: VisionReplayManager!
    private var visionSafetyManager: VisionSafetyManager!

    private let visionViewController = VisionPresentationViewController()
    
    private var alertNoOverspeedingView: UIView!
    private var alertOverspeedingView: UIView!

    private var vehicleState: VehicleState?
    private var speedLimits: SpeedLimits?
    private var carCollisions = [CollisionObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Documents directory path with files uploaded via Finder
        let documentsPath =
            NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                .userDomainMask,
                                                true).first!
        let path = documentsPath.appending("/safety-alerts-drawing")
        
        // create VisionReplayManager with a path to recorded session
        visionManager = try? VisionReplayManager.create(recordPath: path)
        // register its delegate
        visionManager.delegate = self
        
        // create VisionSafetyManager and register as its delegate to receive safety related events
        visionSafetyManager = VisionSafetyManager.create(visionManager: visionManager)
        // register its delegate
        visionSafetyManager.delegate = self

        // configure Vision view to display sample buffers from video source
        visionViewController.set(visionManager: visionManager)
        // add Vision view as a child view
        addVisionView()

        // add views to draw overspeeding alert
        addOverspeedingAlertViews()
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

    private func addOverspeedingAlertViews() {
        alertNoOverspeedingView = UIImageView(image: UIImage(named: "alert"))
        alertNoOverspeedingView.isHidden = true
        alertNoOverspeedingView.tintColor = UIColor.green
        alertNoOverspeedingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(alertNoOverspeedingView)
        NSLayoutConstraint.activate([
            alertNoOverspeedingView.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 1),
            view.trailingAnchor.constraint(equalToSystemSpacingAfter: alertNoOverspeedingView.trailingAnchor, multiplier: 1)
        ])
        
        alertOverspeedingView = UIImageView(image: UIImage(named: "alert"))
        alertOverspeedingView.isHidden = true
        alertOverspeedingView.tintColor = UIColor.red
        alertOverspeedingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(alertOverspeedingView)
        NSLayoutConstraint.activate([
            alertOverspeedingView.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 1),
            view.trailingAnchor.constraint(equalToSystemSpacingAfter: alertOverspeedingView.trailingAnchor, multiplier: 1)
        ])
    }

    private func updateCollisionDrawing() {
        clearCollisionStateDrawings()
        for carCollision in carCollisions {
            let bbox = carCollision.lastDetection.boundingBox
            let bboxColor = carCollision.dangerLevel == .none ? UIColor.green : UIColor.red

            drawCollisionState(in: bbox, with: bboxColor)
        }
    }
    
    private func updateOverspeedingDrawing() {
        // when update is completed all the data has the most current state
        guard let vehicle = self.vehicleState, let limits = self.speedLimits else { return }

        // decide whether speed limit is exceeded by comparing it with the current speed
        let isOverSpeeding = vehicle.speed > limits.speedLimitRange.max
        self.alertOverspeedingView.isHidden = !isOverSpeeding
        self.alertNoOverspeedingView.isHidden = isOverSpeeding
    }
}

extension SafetyAlertsViewController: VisionManagerDelegate {
    func visionManager(_ visionManager: VisionManagerProtocol,
                       didUpdateVehicleState vehicleState: VehicleState) {
        // dispatch to the main queue in order to sync access to `VehicleState` instance
        DispatchQueue.main.async { [weak self] in
            // save the latest state of the vehicle
            self?.vehicleState = vehicleState
        }
    }
    
    func visionManagerDidCompleteUpdate(_ visionManager: VisionManagerProtocol) {
        // dispatch to the main queue in order to work with UIKit elements
        DispatchQueue.main.async { [weak self] in
            // update UI elements
            self?.updateOverspeedingDrawing()
            self?.updateCollisionDrawing()
        }
    }
}

extension SafetyAlertsViewController: VisionSafetyManagerDelegate {
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager,
                             didUpdateRoadRestrictions roadRestrictions: RoadRestrictions) {
        // dispatch to the main queue in order to sync access to `SpeedLimits` instance
        DispatchQueue.main.async { [weak self] in
            // save currenly applied speed limits
            self?.speedLimits = roadRestrictions.speedLimits
        }
    }
    
    func visionSafetyManager(_ visionSafetyManager: VisionSafetyManager,
                             didUpdateCollisions collisions: [CollisionObject]) {
        let carCollisions = collisions.compactMap { collision -> CollisionObject? in
            return collision.object.detectionClass == .car ? collision : nil
        }
        
        // dispatch to the main queue in order to sync access to `[CollisionObject]` array
        DispatchQueue.main.async { [weak self] in
            // update current collisions state
            self?.carCollisions = carCollisions
        }
    }
}

// This comment is here to assure the correct rendering of code snippets in a public documentation
