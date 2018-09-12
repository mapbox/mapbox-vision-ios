//
//  AVCaptureConnection+Orientation.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 6/22/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

extension AVCaptureConnection {
    func set(deviceOrientation: UIDeviceOrientation) {
        if isVideoOrientationSupported,
            UIDeviceOrientationIsLandscape(deviceOrientation),
            let videoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue),
            self.videoOrientation != videoOrientation {
            self.videoOrientation = videoOrientation
        }
    }
}
