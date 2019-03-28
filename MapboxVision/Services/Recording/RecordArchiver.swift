//
//  RecordArchiver.swift
//  MapboxVision
//
//  Created by Maksim on 8/6/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import ZIPFoundation

protocol Archiver {
    func archive(_ folder: URL, destination: URL) throws
}

final class RecordArchiver: Archiver {
    
    func archive(_ folder: URL, destination: URL) throws {
        try FileManager.default.zipItem(at: folder, to: destination, shouldKeepParent: false)
    }
}
