@testable import MapboxVisionAR
import simd
import XCTest

class ARNodeTests: XCTestCase {
    private var arNode: ARNode!

    override func setUp() {
        arNode = ARRootNode()
        super.setUp()
    }

    func testARNodeAfterInitDoesNotHaveAREntity() {
        // Given state from setUp()
        // When // Then
        XCTAssertNil(arNode.entity)
    }

    func testARNodeAfterInitHasExpectedInitialPosition() {
        // Given
        let expectedInitialPosition = float3(0, 0, 0)

        // When // Then
        XCTAssertEqual(arNode.position, expectedInitialPosition)
    }

    func testARNodeAfterInitHasExpectedInitialRotation() {
        // Given
        let expectedInitialRotation = simd_quatf()

        // When // Then
        XCTAssertEqual(arNode.rotation, expectedInitialRotation)
    }

    func testARNodeAfterInitHasExpectedInitialScale() {
        // Given
        let expectedInitialScale = float3(1, 1, 1)

        // When // Then
        XCTAssertEqual(arNode.scale, expectedInitialScale)
    }

    func testAddChildMethodAddsChildNodes() {
        // Given
        let expectedNumberOfChildNodes = Int.random(in: 1...10)

        // When
        for _ in 1...expectedNumberOfChildNodes {
            arNode.add(child: ARRootNode())
        }

        // Then
        XCTAssertEqual(arNode.childs.count, expectedNumberOfChildNodes)
    }

    func testChildNodeHasParentAfterAddChildMethodExecution() {
        // Given
        let childNode = ARRootNode()

        // When
        arNode.add(child: childNode)
        XCTAssertNotNil(childNode.parent)
        XCTAssertTrue((childNode.parent as? ARNode) === arNode)
    }

    func testRemoveAllChildsMethodRemovesChildNodes() {
        // Given
        for _ in 1...Int.random(in: 1...10) {
            arNode.add(child: ARRootNode())
        }

        // When
        arNode.removeAllChilds()

        // Then
        XCTAssertTrue(arNode.childs.isEmpty)
    }
}
