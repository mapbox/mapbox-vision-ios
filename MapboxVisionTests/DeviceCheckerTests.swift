//
//  Created by Dersim Davaod on 5/8/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation
import XCTest
@testable import MapboxVision

class DeviceCheckerTests: XCTestCase {
    func testIsHighPerformanceDeviceReturnsFalseOnIphone7PlusOrLower() {
        // Given iPhone 5s (GSM)
        // When // Then
        XCTAssertFalse(UIDeviceIphone5sGSMStub().isHighPerformance)

        // Given iPhone 5s (Global)
        // When // Then
        XCTAssertFalse(UIDeviceIphone5sGlobalStub().isHighPerformance)

        // Given iPhone 6 Plus
        // When // Then
        XCTAssertFalse(UIDeviceIphone6PlusStub().isHighPerformance)

        // Given iPhone 6
        // When // Then
        XCTAssertFalse(UIDeviceIphone6Stub().isHighPerformance)

        // Given iPhone 6s
        // When // Then
        XCTAssertFalse(UIDeviceIphone6sStub().isHighPerformance)

        // Given iPhone 6s Plus
        // When // Then
        XCTAssertFalse(UIDeviceIphone6sPlusStub().isHighPerformance)

        // Given iPhone SE
        // When // Then
        XCTAssertFalse(UIDeviceIphoneSEStub().isHighPerformance)

        // Given iPhone 7 (CDMA)
        // When // Then
        XCTAssertFalse(UIDeviceIphone7CDMAStub().isHighPerformance)

        // Given iPhone 7 (GSM)
        // When // Then
        XCTAssertFalse(UIDeviceIphone7GSMStub().isHighPerformance)

        // Given iPhone 7 Plus (CDMA)
        // When // Then
        XCTAssertFalse(UIDeviceIphone7PlusCDMAStub().isHighPerformance)

        // Given iPhone 7 Plus (GSM)
        // When // Then
        XCTAssertFalse(UIDeviceIphone7PlusGSMStub().isHighPerformance)
    }

    func testIsHighPerformanceDeviceReturnsTrueOnIphone8OrHigher() {
        // Given iPhone 8 (CDMA)
        // When // Then
        XCTAssertTrue(UIDeviceIphone8CDMAStub().isHighPerformance)

        // Given iPhone 8 (GSM)
        // When // Then
        XCTAssertTrue(UIDeviceIphone8GSMStub().isHighPerformance)

        // Given iPhone 8 Plus (CDMA)
        // When // Then
        XCTAssertTrue(UIDeviceIphone8PlusCDMAStub().isHighPerformance)

        // Given iPhone 8 Plus (GSM)
        // When // Then
        XCTAssertTrue(UIDeviceIphone8PlusGSMStub().isHighPerformance)

        // Given iPhone X (CDMA)
        // When // Then
        XCTAssertTrue(UIDeviceIphoneXCDMAStub().isHighPerformance)

        // Given iPhone X (GSM)
        // When // Then
        XCTAssertTrue(UIDeviceIphoneXGSMStub().isHighPerformance)

        // Given iPhone XS
        // When // Then
        XCTAssertTrue(UIDeviceIphoneXSStub().isHighPerformance)

        // Given iPhone XS Max
        // When // Then
        XCTAssertTrue(UIDeviceIphoneXSMaxStub().isHighPerformance)

        // Given iPhone XS Max China
        // When // Then
        XCTAssertTrue(UIDeviceIphoneXSMaxChinaStub().isHighPerformance)

        // Given iPhone XR
        // When // Then
        XCTAssertTrue(UIDeviceIphoneXRStub().isHighPerformance)
    }

    func testIsHighPerformanceDeviceReturnsFalseOnIphoneNextGeneration() {
        // Given iPhone next gen model
        // When // Then
        XCTAssertFalse(UIDeviceIphoneNextGenerationStub().isHighPerformance)
    }

    func testIsHighPerformanceDeviceReturnsFalseOnIpadDevice() {
        // Given iPad model
        // When // Then
        XCTAssertFalse(UIDeviceIpadStub().isHighPerformance)
    }
}
