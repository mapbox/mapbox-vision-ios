@testable import MapboxVisionAR
import XCTest

class ARSceneTests: XCTestCase {
    private var arScene: ARScene!

    override func setUp() {
        arScene = ARScene()
        super.setUp()
    }

    func testARSceneAfterInitHasARRootNode() {
        // Given state from setUp()
        // When // Then
        XCTAssertEqual(arScene.rootNode.nodeType, .root)
    }

    func testARSceneAfterInitHasARCameraNode() {
        // Given state from setUp()
        // When // Then
        XCTAssertEqual(arScene.cameraNode.nodeType, .camera)
    }

    func testARSceneAfterInitDoesNotHaveOtherChildARLaneNodes() {
        // Given state from setUp()
        // When // Then
        XCTAssertNil(arScene.arLaneNode())
    }

    func testGetChildARLaneNodesMethodReturnsNilWhenThereAreNoARLaneNodeInARScene() {
        // Given state from setUp()
        arScene.rootNode.add(childNode: ARCameraNode())

        // When // Then
        XCTAssertNil(arScene.arLaneNode())
    }
}
