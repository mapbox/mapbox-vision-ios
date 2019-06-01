@testable import MapboxVisionAR
import XCTest

class ARGridNodeTests: XCTestCase {
    private var rootNode: ARGridNode!

    override func setUp() {
        super.setUp()
        rootNode = ARGridNode()
    }
    func testARGridNodeHasGridNodeType() {
        // Given state from setUp()
        // When // Then
        XCTAssertEqual(rootNode.nodeType, .gridNode)
    }

    func testARGridNodeDoesNotHaveAREntity() {
        // Given state from setUp()
        // When // Then
        XCTAssertNil(rootNode.entity)
    }
}
