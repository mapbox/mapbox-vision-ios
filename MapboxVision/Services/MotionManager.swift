//
//  MotionInfo.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 1/15/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation

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
        
        motion.startDeviceMotionUpdates(using: referenceFrame, to: queue) { [weak self] (data, error) in
            guard let data = data else { return }
            self?.handler?(data)
        }
    }
    
    func stop() {
        guard motion.isDeviceMotionActive else { return }
        motion.stopDeviceMotionUpdates()
    }
}

extension MotionInfo.Attitude {
    init(_ attitude: CMAttitude) {
        self.init(pitch: attitude.pitch, roll: attitude.roll, yaw: attitude.yaw, rotationMatrix: attitude.rotationMatrix.value)
    }
}

fileprivate extension CMRotationMatrix {
    var value: MotionInfo.Attitude.RotationMatrix {
        return MotionInfo.Attitude.RotationMatrix(m11: m11, m12: m12, m13: m13, m21: m21, m22: m22, m23: m23, m31: m31, m32: m32, m33: m33)
    }
}

extension MotionInfo.Acceleration {
    init(_ acceleration: CMAcceleration) {
        self.init(x: acceleration.x, y: acceleration.y, z: acceleration.z)
    }
}

extension MotionInfo.Velocity {
    init(_ rotationRate: CMRotationRate) {
        self.init(x: rotationRate.x, y: rotationRate.y, z: rotationRate.z)
    }
}
