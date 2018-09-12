//
//  RecordArchiver.swift
//  MapboxVision
//
//  Created by Maksim on 8/6/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import Zip

protocol Archiver {
    func archive(_ files: [URL], destination: URL) throws
}

final class RecordArchiver: Archiver {
    
    func archive(_ files: [URL], destination: URL) throws {
        try Zip.zipFiles(paths: files, zipFilePath: destination, password: nil, progress: { (progress) in
            print("Compressing \(progress)...")
        })
    }
}
