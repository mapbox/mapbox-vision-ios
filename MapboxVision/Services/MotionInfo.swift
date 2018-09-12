//
//  Motion.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 1/15/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

struct MotionInfo: Encodable {
    struct Acceleration: Encodable {
        let x: Double
        let y: Double
        let z: Double
    }
    
    struct Velocity: Encodable {
        let x: Double
        let y: Double
        let z: Double
    }
    
    struct Attitude: Encodable {
        
        struct RotationMatrix: Encodable {
            let m11: Double
            let m12: Double
            let m13: Double
            let m21: Double
            let m22: Double
            let m23: Double
            let m31: Double
            let m32: Double
            let m33: Double
        }
        
        let pitch: Double
        let roll: Double
        let yaw: Double
        let rotationMatrix: RotationMatrix
    }
    
    // timestamp from the recording start in ms
    let timestamp: Double
    // attitude in radians
    let attitude: Attitude
    // user linear acceleration in G's per component
    let userAcceleration: Acceleration
    // gravity in G's per component
    let gravity: Acceleration
    // angular velocity in radians/second per component
    let angularVelocity: Velocity
}

extension MotionInfo: CustomStringConvertible {
    var description: String {
        return NSString(format: "t: %.5f,\t at: %@,\tua: %@,\tg: %@\tv: %@",
                        timestamp,
                        attitude.description,
                        userAcceleration.description,
                        gravity.description,
                        angularVelocity.description) as String
    }
}

extension MotionInfo.Attitude: CustomStringConvertible {
    var description: String {
        return NSString(format: "p: %+.5f,\tr: %+.5f,\ty: %+.5f", pitch, roll, yaw) as String
    }
}

extension MotionInfo.Acceleration: CustomStringConvertible {
    var description: String {
        return NSString(format: "x: %+.5f,\ty: %+.5f,\tz: %+.5f", x, y, z) as String
    }
}

extension MotionInfo.Velocity: CustomStringConvertible {
    var description: String {
        return NSString(format: "x: %+.5f,\ty: %+.5f,\tz: %+.5f", x, y, z) as String
    }
}
