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

    func testPureCallOfSetNeedsUpdateProjectionMethodDoesNotChangeProjectionMatrix() {
        // Given
        let initialProjectionMatrix = cameraNode.projectionMatrix()

        // When
        cameraNode.setNeedsUpdateProjection()
        let updatedProjectionMatrix = cameraNode.projectionMatrix()

        // Then
        XCTAssertEqual(initialProjectionMatrix, updatedProjectionMatrix)
    }

    func testProjectionMatrixIsNotChangedWhenNearClipPlaneRemainsTheSame() {
        // Given
        cameraNode.nearClipPlane = 250.0
        let initialProjectionMatrix = cameraNode.projectionMatrix()

        // When
        cameraNode.nearClipPlane = 250.0
        let updatedProjectionMatrix = cameraNode.projectionMatrix()

        // Then
        XCTAssertEqual(initialProjectionMatrix, updatedProjectionMatrix)
    }

    func testProjectionMatrixIsNotChangedWhenFarClipPlaneRemainsTheSame() {
        // Given
        cameraNode.farClipPlane = 250.0
        let initialProjectionMatrix = cameraNode.projectionMatrix()

        // When
        cameraNode.farClipPlane = 250.0
        let updatedProjectionMatrix = cameraNode.projectionMatrix()

        // Then
        XCTAssertEqual(initialProjectionMatrix, updatedProjectionMatrix)
    }

    func testProjectionMatrixIsNotChangedWhenFovRadiansRemainsTheSame() {
        // Given
        cameraNode.fovRadians = 250.0
        let initialProjectionMatrix = cameraNode.projectionMatrix()

        // When
        cameraNode.fovRadians = 250.0
        let updatedProjectionMatrix = cameraNode.projectionMatrix()

        // Then
        XCTAssertEqual(initialProjectionMatrix, updatedProjectionMatrix)
    }

    func testProjectionMatrixIsNotChangedWhenAspectRatioRemainsTheSame() {
        // Given
        cameraNode.aspectRatio = 250.0
        let initialProjectionMatrix = cameraNode.projectionMatrix()

        // When
        cameraNode.aspectRatio = 250.0
        let updatedProjectionMatrix = cameraNode.projectionMatrix()

        // Then
        XCTAssertEqual(initialProjectionMatrix, updatedProjectionMatrix)
    }

    func testSetNeedsUpdateProjectionMethodIsCalledWhenNearClipPlaneChanges() {
        // Given
        let initialProjectionMatrix = cameraNode.projectionMatrix()

        // When
        cameraNode.nearClipPlane = 150.0
        let updatedProjectionMatrix = cameraNode.projectionMatrix()

        // Then
        XCTAssertNotEqual(initialProjectionMatrix, updatedProjectionMatrix)
    }

    func testSetNeedsUpdateProjectionMethodIsCalledWhenFarClipPlaneChanges() {
        // Given
        let initialProjectionMatrix = cameraNode.projectionMatrix()

        // When
        cameraNode.farClipPlane = 150.0
        let updatedProjectionMatrix = cameraNode.projectionMatrix()

        // Then
        XCTAssertNotEqual(initialProjectionMatrix, updatedProjectionMatrix)
    }

    func testSetNeedsUpdateProjectionMethodIsCalledWhenFovRadiansChanges() {
        // Given
        let initialProjectionMatrix = cameraNode.projectionMatrix()

        // When
        cameraNode.fovRadians = 150.0
        let updatedProjectionMatrix = cameraNode.projectionMatrix()

        // Then
        XCTAssertNotEqual(initialProjectionMatrix, updatedProjectionMatrix)
    }

    func testSetNeedsUpdateProjectionMethodIsCalledWhenAspectRatioChanges() {
        // Given
        let initialProjectionMatrix = cameraNode.projectionMatrix()

        // When
        cameraNode.aspectRatio = 150.0
        let updatedProjectionMatrix = cameraNode.projectionMatrix()

        // Then
        XCTAssertNotEqual(initialProjectionMatrix, updatedProjectionMatrix)
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
