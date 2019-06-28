// swiftlint:disable comma

@testable import MapboxVisionAR
import simd
import XCTest

class NodeGeometryTests: XCTestCase {
    private var nodeGeometry: NodeGeometry!

    override func setUp() {
        nodeGeometry = NodeGeometry()
        super.setUp()
    }

    func testPureCallOfSetNeedsUpdateWorldTransformMethodDoesNotChangeWorldTransform() {
        // Given
        let initialWorldMatrix = nodeGeometry.worldTransform()

        // When
        nodeGeometry.setNeedsTransformUpdate()
        let updatedWorldMatrix = nodeGeometry.worldTransform()

        // Then
        XCTAssertEqual(initialWorldMatrix, updatedWorldMatrix)
    }

    func testSetNeedsUpdateWorldTransformMethodIsCalledWhenPositionChanges() {
        // Given
        let initialWorldMatrix = nodeGeometry.worldTransform()

        // When
        nodeGeometry.position = float3(0, 1, 2)
        let updatedWorldMatrix = nodeGeometry.worldTransform()

        // Then
        XCTAssertNotEqual(initialWorldMatrix, updatedWorldMatrix)
    }

    func testWorldTransformIsNotChangedWhenPositionRemainsTheSame() {
        // Given
        nodeGeometry.position = float3(0, 1, 2)
        let initialWorldMatrix = nodeGeometry.worldTransform()

        // When
        nodeGeometry.position = float3(0, 1, 2)
        let updatedWorldMatrix = nodeGeometry.worldTransform()

        // Then
        XCTAssertEqual(initialWorldMatrix, updatedWorldMatrix)
    }

    func testSetNeedsUpdateWorldTransformMethodIsCalledWhenRotationChanges() {
        // Given
        let initialWorldMatrix = nodeGeometry.worldTransform()

        // When
        nodeGeometry.rotation = simd_quatf(vector: simd_float4(1, 1, 1, 1))
        let updatedWorldMatrix = nodeGeometry.worldTransform()

        // Then
        XCTAssertNotEqual(initialWorldMatrix, updatedWorldMatrix)
    }

    func testWorldTransformIsNotChangedWhenRotationRemainsTheSame() {
        // Given
        nodeGeometry.rotation = simd_quatf(vector: simd_float4(1, 1, 1, 1))
        let initialWorldMatrix = nodeGeometry.worldTransform()

        // When
        nodeGeometry.rotation = simd_quatf(vector: simd_float4(1, 1, 1, 1))
        let updatedWorldMatrix = nodeGeometry.worldTransform()

        // Then
        XCTAssertEqual(initialWorldMatrix, updatedWorldMatrix)
    }

    func testSetNeedsUpdateWorldTransformMethodIsCalledWhenScaleChanges() {
        // Given
        let initialWorldMatrix = nodeGeometry.worldTransform()

        // When
        nodeGeometry.scale = float3(0, 1, 2)
        let updatedWorldMatrix = nodeGeometry.worldTransform()

        // Then
        XCTAssertNotEqual(initialWorldMatrix, updatedWorldMatrix)
    }

    func testWorldTransformIsNotChangedWhenScaleRemainsTheSame() {
        // Given
        nodeGeometry.scale = float3(0, 1, 2)
        let initialWorldMatrix = nodeGeometry.worldTransform()

        // When
        nodeGeometry.scale = float3(0, 1, 2)
        let updatedWorldMatrix = nodeGeometry.worldTransform()

        // Then
        XCTAssertEqual(initialWorldMatrix, updatedWorldMatrix)
    }

    func testWorldTransformMethodCorrectlyUpdatesWorldTransform() {
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
