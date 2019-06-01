@testable import MapboxVisionAR
import XCTest

class ARRootNodeTests: XCTestCase {
    private var rootNode: ARRootNode!

    override func setUp() {
        super.setUp()
        rootNode = ARRootNode()
    }
    func testARRootNodeHasRootNodeType() {
        // Given state from setUp()
        // When // Then
        XCTAssertEqual(rootNode.nodeType, .rootNode)
    }

    func testARRootNodeDoesNotHaveAREntity() {
        // Given state from setUp()
        // When // Then
        XCTAssertNil(rootNode.entity)
    }
}
