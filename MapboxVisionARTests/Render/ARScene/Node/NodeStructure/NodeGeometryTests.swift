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

    func testUpdatesCachedMatrix() {
        // Given
        let initialState = 0
        let updatedState = 0
        // When
        // Then
        XCTAssertNotEqual(initialState, updatedState)
    }
}
