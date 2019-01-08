//
//  DeviceProviderTests.swift
//  MapboxVisionTests
//
//  Created by Alexander Pristavko on 11/16/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import XCTest

@testable import MapboxVision

final class DeviceProviderTests: XCTestCase {
    
    func testIDReset() {
        let deviceInfo = DeviceInfoProvider()
        let initialID = deviceInfo.id
        
        deviceInfo.reset()
        
        XCTAssertNotEqual(initialID, deviceInfo.id)
    }
}
