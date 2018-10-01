//
//  MockArchiver.swift
//  MapboxVisionTests
//
//  Created by Maksim on 10/2/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
@testable import MapboxVision

final class MockArchiver: Archiver {
    
    var archives: [URL: [URL]] = [:]
    
    func archive(_ files: [URL], destination: URL) throws {
        archives[destination] = files
    }
}
