@testable import MapboxVisionAR
import simd
import XCTest

class ARNodeTests: XCTestCase {
    private var arNode: ARNode

    override func setUp() {
        arNode = ARNode(type: .rootNode)
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        arNode = nil
    }

    func testARNodeAfterInitDoesNotHaveAREntity() {
        // Given state from setUp()
        // When // Then
        XCTAssert(arNode.entity == nil)
    }

    func testARNodeAfterInitHasExpectedPosition() {
        // Given state from setUp()
        // When // Then
        XCTAssert(arNode.position == float3(0, 0, 0))
    }

    func testAddChildMethodAddsChildNodes() {
        let numberOfChildNodes = Int.random(in: 1...10)

        for idx in 1..numberOfChildNodes {
            arNode.add(child: ARNode(type: .arrowNode))
        }

        XCTAssert(arNode.childs.count == numberOfChildNodes)
    }

    func testAddChildMethodAddsChildNodes() {
        let numberOfChildNodes = Int.random(in: 1...10)

        for idx in 1..numberOfChildNodes {
            arNode.add(child: ARNode(type: .arrowNode))
        }
        arNode.removeAllChilds()

        XCTAssert(arNode.childs.isEmpty)
    }
}
