@testable import MapboxVisionAR
import XCTest

class ARSceneTests: XCTestCase {
    private var arScene: ARScene!

    override func setUp() {
        arScene = ARScene()
        super.setUp()
    }

    func testARSceneAfterInitARRootNode() {
        // Given state from setUp()
        // When // Then
        XCTAssertEqual(arScene.rootNode.nodeType, .rootNode)
    }

    func testARSceneAfterInitHasARCameraNode() {
        // Given state from setUp()
        // When // Then
        XCTAssertEqual(arScene.cameraNode.nodeType, .cameraNode)
    }

    func testARSceneAfterInitDoesNotHaveOtherChildARLaneNodes() {
        // Given state from setUp()
        // When // Then
        XCTAssertTrue(arScene.getChildARLaneNodes().isEmpty)
    }

    func testGetChildARLaneNodesMethodReturnsZeroARNodeWhenThereAreNoARLaneNodesInARScene() {
        // Given state from setUp()
        arScene.rootNode.add(child: ARCameraNode())

        // When // Then
        XCTAssertTrue(arScene.getChildARLaneNodes().isEmpty)
    }
}
