import CoreLocation
import CoreMotion
import Foundation

final class MotionManager {
    private let motion = CMMotionManager()
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private enum Constants {
        static let referenceFrame: CMAttitudeReferenceFrame = .xArbitraryZVertical
    }

    var handler: ((CMDeviceMotion, CMAttitudeReferenceFrame) -> Void)?

    func start(updateInterval: Double) {
        guard motion.isDeviceMotionAvailable else { return }

        motion.deviceMotionUpdateInterval = updateInterval
        motion.showsDeviceMovementDisplay = true

        motion.startDeviceMotionUpdates(using: Constants.referenceFrame, to: queue) { [weak self] data, _ in
            guard let data = data, let referenceFrame = self?.motion.attitudeReferenceFrame else { return }

            self?.handler?(data, referenceFrame)
        }
    }

    func stop() {
        guard motion.isDeviceMotionActive else { return }
        motion.stopDeviceMotionUpdates()
    }
}
