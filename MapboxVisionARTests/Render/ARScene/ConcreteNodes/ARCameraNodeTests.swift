@testable import MapboxVisionAR
import XCTest

class ARLaneNodeTests: XCTestCase {
    private var rootNode: ARLaneNode!

    override func setUp() {
        super.setUp()
        // TODO: create fake entity
        _ = ARLaneEntity(with: _, and: _)
        rootNode = ARLaneNode(arLaneEntity: _)
    }
    func testARRootNodeHasGridNodeType() {
        // Given state from setUp()
        // When // Then
        XCTAssertEqual(rootNode.nodeType, .arrowNode)
    }

    func testARRootNodeDoesNotHaveAREntity() {
        // Given state from setUp()
        // When // Then
        XCTAssertNil(rootNode.entity)
    }
}
