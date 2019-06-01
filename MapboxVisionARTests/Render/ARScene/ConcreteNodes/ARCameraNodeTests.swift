@testable import MapboxVisionAR
import simd
import XCTest

class ARCameraNodeTests: XCTestCase {
    private var cameraNode: ARCameraNode!

    override func setUp() {
        super.setUp()
        cameraNode = ARCameraNode()
    }

    func testARCameraNodeHasGridNodeType() {
        // Given state from setUp()
        // When // Then
        XCTAssertEqual(cameraNode.nodeType, .cameraNode)
    }

    func testARCameraNodeDoesNotHaveAREntity() {
        // Given state from setUp()
        // When // Then
        XCTAssertNil(cameraNode.entity)
    }

    func testNeedsUpdateProjectionFlagHasExpectedInitialState() { // TODO: rename consistently - has expected initial SOMETHING  +!!! review all names
        // Given state from setUp()
        let expectedInitialState = true

        // When // Then
        XCTAssertEqual(cameraNode.needsUpdateProjection, expectedInitialState)
    }

    func testNearClipPlaneHasExpectedInitialState() {
        // Given state from setUp()
        let expectedInitialState: Float = 0.01

        // When // Then
        XCTAssertEqual(cameraNode.nearClipPlane, expectedInitialState)
    }

    func testFarClipPlaneHasExpectedInitialState() {
        // Given state from setUp()
        let expectedInitialState: Float = 1000

        // When // Then
        XCTAssertEqual(cameraNode.farClipPlane, expectedInitialState)
    }

    func testFovRadiansHasExpectedInitialState() {
        // Given state from setUp()
        let expectedInitialState = degreesToRadians(60)

        // When // Then
        XCTAssertEqual(cameraNode.fovRadians, expectedInitialState)
    }

    func testAspectRatioHasExpectedInitialState() {
        // Given state from setUp()
        let expectedInitialState = Float(4.0 / 3.0)

        // When // Then
        XCTAssertEqual(cameraNode.aspectRatio, expectedInitialState)
    }

    func testCachedProjectionMatrixHasExpectedInitialState() {
        // Given state from setUp()
        let expectedInitialState = float4x4()

        // When // Then
        XCTAssertEqual(cameraNode.cachedProjectionMatrix, expectedInitialState)
    }

    func testSetNeedsUpdateProjectionMethodSetsNeedsUpdateProjectionFlag() {
        // Given
        let expectedFinalState = true
        _ = cameraNode.projectionMatrix()

        // When
        cameraNode.setNeedsUpdateProjection()

        // Then
        XCTAssertEqual(cameraNode.needsUpdateProjection, expectedFinalState)
    }

    func testProjectionMatrixMethodResetsNeedsUpdateProjectionFlag() {
        // Given
        let expectedFinalState = false

        // When
        _ = cameraNode.projectionMatrix()

        // Then
        XCTAssertEqual(cameraNode.needsUpdateProjection, expectedFinalState)
    }

    func testSetNeedsUpdateProjectionMethodIsCalledWhenNearClipPlaneChanges() {
        // Given
        // When
        cameraNode.nearClipPlane = Float(1.0)

        // Then
    }

    func testSetNeedsUpdateProjectionMethodIsCalledWhenFarClipPlaneChanges() {
        // Given
        // When
        cameraNode.farClipPlane = Float(1.0)

        // Then
        XCTAssertEqual(cameraNode.needsUpdateProjection, true)
    }

    func testSetNeedsUpdateProjectionMethodIsCalledWhenFovRadiansChanges() {
        // Given
        // When
        cameraNode.fovRadians = Float(1.0)

        // Then
    }

    func testSetNeedsUpdateProjectionMethodIsCalledWhenAspectRatioChanges() {
        // Given
        let expectedFlagState = true
        _ = cameraNode.projectionMatrix()

        // When
        cameraNode.aspectRatio = Float(1.0)

        // Then
        XCTAssertEqual(cameraNode.needsUpdateProjection, expectedFlagState)
    }

    func testProjectionMatrixMethodWorks() {
    }

    func testCachedProjectionMatrixHasNewStateWhen() {
    }

    func testFrameSizeChangesAspectRatio() {
    }
}
