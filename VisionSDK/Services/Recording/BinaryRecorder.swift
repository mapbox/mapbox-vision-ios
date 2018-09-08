//
//  BinaryRecorder.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 1/27/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

final class BinaryRecorder {
    static func record(data: Data, at path: String) {
        FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
    }
}
