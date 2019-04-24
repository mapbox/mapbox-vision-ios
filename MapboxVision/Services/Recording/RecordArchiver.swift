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
    
    enum RecordArchiverError: Error {
        case cantCreateArchive(URL)
    }
    
    func archive(_ files: [URL], destination: URL) throws {
        guard let archive = Archive(url: destination, accessMode: .create) else {
            throw RecordArchiverError.cantCreateArchive(destination)
        }
        
        for file in files {
            try archive.addEntry(with: file.lastPathComponent, relativeTo: file.deletingLastPathComponent())
        }
    }
}
