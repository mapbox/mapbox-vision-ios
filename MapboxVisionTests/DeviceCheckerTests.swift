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
        XCTAssertFalse(UIDeviceIphone5sGSMStub().isHighPerformanceIphone)

        // Given iPhone 5s (Global)
        // When // Then
        XCTAssertFalse(UIDeviceIphone5sGlobalStub().isHighPerformanceIphone)

        // Given iPhone 6 Plus
        // When // Then
        XCTAssertFalse(UIDeviceIphone6PlusStub().isHighPerformanceIphone)

        // Given iPhone 6
        // When // Then
        XCTAssertFalse(UIDeviceIphone6Stub().isHighPerformanceIphone)

        // Given iPhone 6s
        // When // Then
        XCTAssertFalse(UIDeviceIphone6sStub().isHighPerformanceIphone)

        // Given iPhone 6s Plus
        // When // Then
        XCTAssertFalse(UIDeviceIphone6sPlusStub().isHighPerformanceIphone)

        // Given iPhone SE
        // When // Then
        XCTAssertFalse(UIDeviceIphoneSEStub().isHighPerformanceIphone)

        // Given iPhone 7 (CDMA)
        // When // Then
        XCTAssertFalse(UIDeviceIphone7CDMAStub().isHighPerformanceIphone)

        // Given iPhone 7 (GSM)
        // When // Then
        XCTAssertFalse(UIDeviceIphone7GSMStub().isHighPerformanceIphone)

        // Given iPhone 7 Plus (CDMA)
        // When // Then
        XCTAssertFalse(UIDeviceIphone7PlusCDMAStub().isHighPerformanceIphone)

        // Given iPhone 7 Plus (GSM)
        // When // Then
        XCTAssertFalse(UIDeviceIphone7PlusGSMStub().isHighPerformanceIphone)
    }

    func testIsHighPerformanceDeviceReturnsTrueOnIphone8OrHigher() {
        // Given iPhone 8 (CDMA)
        // When // Then
        XCTAssertTrue(UIDeviceIphone8CDMAStub().isHighPerformanceIphone)

        // Given iPhone 8 (GSM)
        // When // Then
        XCTAssertTrue(UIDeviceIphone8GSMStub().isHighPerformanceIphone)

        // Given iPhone 8 Plus (CDMA)
        // When // Then
        XCTAssertTrue(UIDeviceIphone8PlusCDMAStub().isHighPerformanceIphone)

        // Given iPhone 8 Plus (GSM)
        // When // Then
        XCTAssertTrue(UIDeviceIphone8PlusGSMStub().isHighPerformanceIphone)

        // Given iPhone X (CDMA)
        // When // Then
        XCTAssertTrue(UIDeviceIphoneXCDMAStub().isHighPerformanceIphone)

        // Given iPhone X (GSM)
        // When // Then
        XCTAssertTrue(UIDeviceIphoneXGSMStub().isHighPerformanceIphone)

        // Given iPhone XS
        // When // Then
        XCTAssertTrue(UIDeviceIphoneXSStub().isHighPerformanceIphone)

        // Given iPhone XS Max
        // When // Then
        XCTAssertTrue(UIDeviceIphoneXSMaxStub().isHighPerformanceIphone)

        // Given iPhone XS Max China
        // When // Then
        XCTAssertTrue(UIDeviceIphoneXSMaxChinaStub().isHighPerformanceIphone)

        // Given iPhone XR
        // When // Then
        XCTAssertTrue(UIDeviceIphoneXRStub().isHighPerformanceIphone)
    }

    func testIsHighPerformanceDeviceReturnsFalseOnIphoneNextGeneration() {
        // Given iPhone next gen model
        // When // Then
        XCTAssertFalse(UIDeviceIphoneNextGenerationStub().isHighPerformanceIphone)
    }

    func testIsHighPerformanceDeviceReturnsFalseOnIpadDevice() {
        // Given iPad model
        // When // Then
        XCTAssertFalse(UIDeviceIpadStub().isHighPerformanceIphone)
    }
}
