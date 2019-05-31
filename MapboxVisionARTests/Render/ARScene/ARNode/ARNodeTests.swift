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

    func testARNodeAfterInitHasExpectedPosition() {
        // Given
        let expectedInitialPosition = float3(0, 0, 0)

        // When // Then
        XCTAssertTrue(arNode.position == expectedInitialPosition)
    }

    func testAddChildMethodAddsChildNodes() {
        // Given
        let expectedNumberOfChildNodes = Int.random(in: 1...10)

        // When
        for _ in 1...expectedNumberOfChildNodes {
            arNode.add(child: ARRootNode())
        }

        // Then
        XCTAssertTrue(arNode.childs.count == expectedNumberOfChildNodes)
    }

    func testRemoveAllChildsMethodRemovesChildNodes() {
        // Given
        for _ in 1...Int.random(in: 1...10) {
            arNode.add(child: ARRootNode())
        }

        // When
        arNode?.removeAllChilds()

        // Then
        XCTAssertTrue(arNode.childs.isEmpty)
    }
}
