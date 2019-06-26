@testable import MapboxVisionAR
import simd
import XCTest

class ARCameraNodeTests: XCTestCase {
    private var cameraNode: ARCameraNode!

    override func setUp() {
        super.setUp()
        cameraNode = ARCameraNode()
    }

    func testARCameraNodeHasCameraNodeType() {
        // Given state from setUp()
        // When // Then
        XCTAssertEqual(cameraNode.nodeType, .camera)
    }

    func testNeedsUpdateProjectionFlagHasExpectedInitialState() {
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

    func testProjectionMatrixMethodReturnsValueEqualsToCachedValue() {
        // Given
        cameraNode.farClipPlane = 10

        // When
        let valueReturnedFromMethod = cameraNode.projectionMatrix()

        // Then
        XCTAssertEqual(valueReturnedFromMethod, cameraNode.cachedProjectionMatrix)
    }

    func testSetNeedsUpdateProjectionMethodIsCalledWhenNearClipPlaneChanges() {
        // Given
        let expectedFlagState = true

        // When
        cameraNode.nearClipPlane = Float(1.0)

        // Then
        XCTAssertEqual(cameraNode.needsUpdateProjection, expectedFlagState)
    }

    func testSetNeedsUpdateProjectionMethodIsCalledWhenFarClipPlaneChanges() {
        // Given
        let expectedFlagState = true

        // When
        cameraNode.farClipPlane = Float(1.0)

        // Then
        XCTAssertEqual(cameraNode.needsUpdateProjection, expectedFlagState)
    }

    func testSetNeedsUpdateProjectionMethodIsCalledWhenFovRadiansChanges() {
        // Given
        let expectedFlagState = true

        // When
        cameraNode.fovRadians = Float(1.0)

        // Then
        XCTAssertEqual(cameraNode.needsUpdateProjection, expectedFlagState)
    }

    func testSetNeedsUpdateProjectionMethodIsCalledWhenAspectRatioChanges() {
        // Given
        let expectedFlagState = true

        // When
        cameraNode.aspectRatio = Float(1.0)

        // Then
        XCTAssertEqual(cameraNode.needsUpdateProjection, expectedFlagState)
    }

    func testProjectionMatrixMethodCorrectlyUpdatesProjectionMatrix() {
        // Given
        let expectedProjectionMatrix = matrix_float4x4(
            float4(3.79787731,          0,  0,  0),
            float4(0,          7.59575462,  0,  0),
            float4(0,                   0, -3, -1),
            float4(0,                   0, -4,  1)
        )
        cameraNode.nearClipPlane = 1
        cameraNode.farClipPlane = 2
        cameraNode.fovRadians = degreesToRadians(15)
        cameraNode.aspectRatio = 2

        // When
        let updatedProjectionMatrix = cameraNode.projectionMatrix()

        // Then
        XCTAssertEqual(updatedProjectionMatrix, expectedProjectionMatrix)
    }
}
