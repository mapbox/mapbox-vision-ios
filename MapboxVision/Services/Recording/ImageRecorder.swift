//
//  FrameRecorder.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 1/9/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import UIKit

final class ImageRecorder {
    func record(image: UIImage, to path: String) {
        DispatchQueue.global(qos: .utility).async {
            guard let data = UIImagePNGRepresentation(image) else { return }
            do {
                try data.write(to: URL(fileURLWithPath: path))
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
}
