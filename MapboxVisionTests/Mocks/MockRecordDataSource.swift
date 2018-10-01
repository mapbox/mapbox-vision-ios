//
//  MockRecordDataSource.swift
//  MapboxVisionTests
//
//  Created by Maksim on 10/2/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
@testable import MapboxVision

final class MockRecordDataSource: RecordDataSource {
    
    var removedFiles: [URL] = []
    
    var baseURL: URL {
        return URL(fileURLWithPath: "")
    }
    
    var recordDirectories: [URL] = []
    
    func removeFile(at url: URL) {
        removedFiles.append(url)
    }
}
