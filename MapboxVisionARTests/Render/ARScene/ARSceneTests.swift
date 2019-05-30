@testable import MapboxVisionAR
import XCTest

class ARSceneTests: XCTestCase {
    private var arScene: ARScene!

    override func setUp() {
        arScene = ARScene()
        super.setUp()
    }

    func testARSceneAfterInitARNodeWithRootNodeType() {
        // Given state from setUp()
        // When // Then
        XCTAssertTrue(arScene.rootNode.nodeType == .rootNode)
    }

    func testARSceneAfterInitHasARNodeWithCameraNodeType() {
        // Given state from setUp()
        // When // Then
        XCTAssertTrue(arScene.cameraNode.nodeType == .cameraNode)
    }

    func testARSceneAfterInitDoesNotHaveOtherChildARLaneNodes() {
        // Given state from setUp()
        // When // Then
        XCTAssertTrue(arScene.getChildARLaneNodes()!.isEmpty)
    }
}
