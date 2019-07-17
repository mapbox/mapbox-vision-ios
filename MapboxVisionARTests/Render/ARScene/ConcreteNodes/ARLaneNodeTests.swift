@testable import MapboxVisionAR
import simd
import XCTest

class ARLaneNodeTests: XCTestCase {
    private var laneNode: ARLaneNode!

    override func setUp() {
        super.setUp()
        laneNode = ARLaneNode()
    }

    func testARLaneNodeHasRootNodeType() {
        // Given state from setUp()
        // When // Then
        XCTAssertEqual(laneNode.nodeType, .lane)
    }

    func testARLaneNodeAfterInitHasExpectedInitialLaneColor() {
        // Given state from setUp()
        let expectedLaneColor = ARConstants.laneDefaultColor

        // When
        let initialLaneColor = laneNode.arMaterial.diffuseColor

        // Then
        XCTAssertEqual(initialLaneColor, expectedLaneColor)
    }

    func testARLaneNodeAfterInitHasExpectedInitialAmbientLightColor() {
        // Given state from setUp()
        let expectedLaneAmbientLightColor = ARConstants.laneDefaultColor.xyz

        // When
        let initialLaneAmbientLightColor = laneNode.arMaterial.ambientLightColor

        // Then
        XCTAssertEqual(initialLaneAmbientLightColor, expectedLaneAmbientLightColor)
    }

    func testARLaneNodeAfterInitHasExpectedInitialLaneLightColor() {
        // Given state from setUp()
        let expectedLaneLightColor = ARConstants.laneDefaultLightColor

        // When
        let initialLaneLightColor = laneNode.arMaterial.light.color

        // Then
        XCTAssertEqual(initialLaneLightColor, expectedLaneLightColor)
    }

    func testARLaneNodeAfterInitHasExpectedInitialLaneLightPosition() {
        // Given state from setUp()
        let expectedLaneLightPosition = ARConstants.laneDefaultLightPosition

        // When
        let initialLaneLightPosition = laneNode.arMaterial.light.position

        // Then
        XCTAssertEqual(initialLaneLightPosition, expectedLaneLightPosition)
    }

    func testSetLaneColorMethodSetsNewLaneColor() {
        // Given
        let randomizedRedComponent = CGFloat(Int.random(in: 0...255) / 255)
        let randomizedGreenComponent = CGFloat(Int.random(in: 0...255) / 255)
        let randomizedBlueComponent = CGFloat(Int.random(in: 0...255) / 255)
        let randomizedAlphaComponent = CGFloat(Float.random(in: 0.0...1.0))
        let expectedFinalColor = UIColor(red: randomizedRedComponent,
                                         green: randomizedGreenComponent,
                                         blue: randomizedBlueComponent,
                                         alpha: randomizedAlphaComponent)

        // When
        laneNode.set(laneColor: expectedFinalColor)

        // Then
        XCTAssertEqual(laneNode.arMaterial.diffuseColor.x, Float(randomizedRedComponent))
        XCTAssertEqual(laneNode.arMaterial.diffuseColor.y, Float(randomizedGreenComponent))
        XCTAssertEqual(laneNode.arMaterial.diffuseColor.z, Float(randomizedBlueComponent))
        XCTAssertEqual(laneNode.arMaterial.diffuseColor.w, Float(randomizedAlphaComponent))
    }

    func testSetLaneWidthMethodSetsNewLaneWidth() {
        // Given
        let expectedFinalWidth = Float.random(in: 1.0...1000.0)

        // When
        laneNode.set(laneWidth: expectedFinalWidth)

        // Then
        XCTAssertEqual(laneNode.width, expectedFinalWidth)
    }

    func testSetLaneLightPositionMethodSetsNewLaneLightPosition() {
        // Given
        let expectedLightPosition = float3(Float.random(in: 0.0...100.0),
                                           Float.random(in: 0.0...100.0),
                                           Float.random(in: 0.0...100.0))

        // When
        laneNode.set(laneLightPosition: expectedLightPosition)

        // Then
        XCTAssertEqual(laneNode.arMaterial.light.position, expectedLightPosition)
    }

    func testSetLaneLightColorMethodSetsNewLaneLightColor() {
        // Given
        // TBD - RENAME RANDOMIZED!
        let randomizedRedComponent = CGFloat(Int.random(in: 0...255) / 255)
        let randomizedGreenComponent = CGFloat(Int.random(in: 0...255) / 255)
        let randomizedBlueComponent = CGFloat(Int.random(in: 0...255) / 255)
        let expectedFinalColor = UIColor(red: randomizedRedComponent,
                                         green: randomizedGreenComponent,
                                         blue: randomizedBlueComponent,
                                         alpha: 1.0)

        // When
        laneNode.set(laneLightColor: expectedFinalColor)

        // Then
        XCTAssertEqual(laneNode.arMaterial.light.color.x, Float(randomizedRedComponent))
        XCTAssertEqual(laneNode.arMaterial.light.color.y, Float(randomizedGreenComponent))
        XCTAssertEqual(laneNode.arMaterial.light.color.z, Float(randomizedBlueComponent))
    }

    func testSetLaneAmbientColorMethodSetsNewLaneAmbientColor() {
        // Given
        // TBD - RENAME RANDOMIZED!
        let randomizedRedComponent = CGFloat(Int.random(in: 0...255) / 255)
        let randomizedGreenComponent = CGFloat(Int.random(in: 0...255) / 255)
        let randomizedBlueComponent = CGFloat(Int.random(in: 0...255) / 255)
        let expectedFinalColor = UIColor(red: randomizedRedComponent,
                                         green: randomizedGreenComponent,
                                         blue: randomizedBlueComponent,
                                         alpha: 1.0)

        // When
        laneNode.set(laneAmbientColor: expectedFinalColor)

        // Then
        XCTAssertEqual(laneNode.arMaterial.ambientLightColor.x, Float(randomizedRedComponent))
        XCTAssertEqual(laneNode.arMaterial.ambientLightColor.y, Float(randomizedGreenComponent))
        XCTAssertEqual(laneNode.arMaterial.ambientLightColor.z, Float(randomizedBlueComponent))
    }
}
