@testable import MapboxVisionAR
import XCTest

class ARSceneTests: XCTestCase {
    private var arScene: ARScene

    override func setUp() {
        arScene = ARScene()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        arScene = nil
    }

    func testARSceneAfterInitHasRootNodeWithRootNodeType() {
        // Given state from setUp()
        // When // Then
        XCTAssert(arScene.rootNode.nodeType == .rootNode)
    }

    func testARSceneAfterInitHasCameraNodeWithCameraNodeType() {
        // Given state from setUp()
        // When // Then
        XCTAssert(arScene.cameraNode.nodeType == .cameraNode)
    }

    func testARSceneAfterInitDoesNotHaveChildARLaneNodes() {
        // Given state from setUp()
        // When // Then
        XCTAssert(arScene.getChildARLaneNodes() == nil)
    }
}
