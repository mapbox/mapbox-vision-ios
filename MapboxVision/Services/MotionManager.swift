import CoreLocation
import CoreMotion
import Foundation

final class MotionManager {
    private let motion: CMMotionManager = CMMotionManager()
    private let referenceFrame: CMAttitudeReferenceFrame
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    var handler: ((CMDeviceMotion) -> Void)?

    init(with referenceFrame: CMAttitudeReferenceFrame) {
        self.referenceFrame = referenceFrame
    }

    func start(updateInterval: Double) {
        guard motion.isDeviceMotionAvailable else { return }

        motion.deviceMotionUpdateInterval = updateInterval
        motion.showsDeviceMovementDisplay = true

        motion.startDeviceMotionUpdates(using: referenceFrame, to: queue) { [weak self] data, _ in
            guard let data = data else { return }
            self?.handler?(data)
        }
    }

    func stop() {
        guard motion.isDeviceMotionActive else { return }
        motion.stopDeviceMotionUpdates()
    }
}
