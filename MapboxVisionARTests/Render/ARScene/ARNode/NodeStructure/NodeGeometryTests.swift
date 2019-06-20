@testable import MapboxVisionAR
import simd
import XCTest

class NodeGeometryTests: XCTestCase {
    private var nodeGeometry: NodeGeometry!

    override func setUp() {
        nodeGeometry = NodeGeometry()
        super.setUp()
    }

    func testNeedsUpdateWorldTransformFlagHasExpectedInitialState() {
        // Given state from setUp()
        let expectedInitialState = true

        // When // Then
        XCTAssertEqual(nodeGeometry.needsUpdateWorldTransform, expectedInitialState)
    }

    func testCachedWorldTransformHasExpectedInitialState() {
        // Given state from setUp()
        let expectedInitialState = matrix_identity_float4x4

        // When // Then
        XCTAssertEqual(nodeGeometry.cachedWorldTransform, expectedInitialState)
    }

    func testWorldTransformMethodResetsNeedsUpdateWorldTransformFlag() {
        // Given state from setUp()
        let expectedFinalState = false

        // When
        _ = nodeGeometry.worldTransform()

        // Then
        XCTAssertEqual(nodeGeometry.needsUpdateWorldTransform, expectedFinalState)
    }

    func testSetNeedsUpdateWorldTransformMethodSetsNeedsUpdateWorldTransformFlag() {
        // Given
        let expectedFinalState = true
        _ = nodeGeometry.worldTransform()

        // When
        nodeGeometry.setNeedsTransformUpdate()

        // Then
        XCTAssertEqual(nodeGeometry.needsUpdateWorldTransform, expectedFinalState)
    }

    func testWorldTransformMethodReturnsValueEqualsToCachedValue() {
        // Given
        nodeGeometry.position = float3(1, 2, 3)

        // When
        let valueReturnedFromMethod = nodeGeometry.worldTransform()

        // Then
        XCTAssertEqual(valueReturnedFromMethod, nodeGeometry.cachedWorldTransform)
    }

    func testSetNeedsUpdateWorldTransformMethodIsCalledWhenPositionChanges() {
        // Given
        _ = nodeGeometry.worldTransform()

        // When
        nodeGeometry.position = float3(0, 0, 0)

        // Then
        XCTAssertTrue(nodeGeometry.needsUpdateWorldTransform)
    }

    func testSetNeedsUpdateWorldTransformMethodIsCalledWhenRotationChanges() {
        // Given
        _ = nodeGeometry.worldTransform()

        // When
        nodeGeometry.rotation = simd_quatf()

        // Then
        XCTAssertTrue(nodeGeometry.needsUpdateWorldTransform)
    }

    func testSetNeedsUpdateWorldTransformMethodIsCalledWhenScaleChanges() {
        // Given
        _ = nodeGeometry.worldTransform()

        // When
        nodeGeometry.scale = float3(0, 0, 0)

        // Then
        XCTAssertTrue(nodeGeometry.needsUpdateWorldTransform)
    }

    func testWorldTransformMethodCorrectlyUpdatesWorldTranform() {
        // Given
        let expectedWorldTransform = matrix_float4x4(
            float4(-25,  56, -30, 0),
            float4(-20, -38,  60, 0),
            float4( 22,   8, -27, 0),
            float4(  1,   2,   3, 1)
        )
        nodeGeometry.position = float3(1, 2, 3)
        nodeGeometry.rotation = simd_quatf(ix: 1, iy: 2, iz: 3, r: 4)
        nodeGeometry.scale = float3(1, 2, 3)

        // When
        let updatedWorldTransform = nodeGeometry.worldTransform()

        // Then
        XCTAssertEqual(updatedWorldTransform, expectedWorldTransform)
    }
}
