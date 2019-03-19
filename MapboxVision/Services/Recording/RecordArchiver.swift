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
    func archive(_ files: [URL], destination: URL) throws
}

final class RecordArchiver: Archiver {
    
    func archive(_ files: [URL], destination: URL) throws {
        for file in files {
            try FileManager.default.zipItem(at: file, to: destination)
        }
    }
}
