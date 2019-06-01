@testable import MapboxVisionAR
import simd
import XCTest

class NodeGeometryTests: XCTestCase {
    private var nodeGeometry: NodeGeometry!

    override func setUp() {
        nodeGeometry = NodeGeometry()
        super.setUp()
    }

    func testNeedTransformUpdateFlagHasExpectedInitialState() {
        // Given state from setUp()
        let expectedInitialState = true

        // When // Then
        XCTAssertEqual(nodeGeometry.needTransformUpdate, expectedInitialState)
    }

    func testCachedTransformMatrixHasExpectedInitialState() {
        // Given state from setUp()
        let expectedInitialState = matrix_identity_float4x4

        // When // Then
        XCTAssertEqual(nodeGeometry.cachedTransformMatrix, expectedInitialState)
    }

    func testWorldTransformMethodResetsNeedTransformUpdateFlag() {
        // Given state from setUp()
        let expectedFinalState = false

        // When
        _ = nodeGeometry.worldTransform()

        // Then
        XCTAssertEqual(nodeGeometry.needTransformUpdate, expectedFinalState)
    }

    func testSetNeedTransformUpdateMethodSetsNeedTransformUpdateFlag() {
        // Given
        let expectedFinalState = true
        _ = nodeGeometry.worldTransform()

        // When
        nodeGeometry.setNeedTransformUpdate()

        // Then
        XCTAssertEqual(nodeGeometry.needTransformUpdate, expectedFinalState)
    }

    func testSetNeedTransformUpdateMethodIsCalledWhenPositionChanges() {
        // Given
        _ = nodeGeometry.worldTransform()

        // When
        nodeGeometry.position = float3(0, 0, 0)

        // Then
        XCTAssertTrue(nodeGeometry.needTransformUpdate)
    }

    func testSetNeedTransformUpdateMethodIsCalledWhenRotationChanges() {
        // Given
        _ = nodeGeometry.worldTransform()

        // When
        nodeGeometry.rotation = simd_quatf()

        // Then
        XCTAssertTrue(nodeGeometry.needTransformUpdate)
    }

    func testSetNeedTransformUpdateMethodIsCalledWhenScaleChanges() {
        // Given
        _ = nodeGeometry.worldTransform()

        // When
        nodeGeometry.scale = float3(0, 0, 0)

        // Then
        XCTAssertTrue(nodeGeometry.needTransformUpdate)
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
