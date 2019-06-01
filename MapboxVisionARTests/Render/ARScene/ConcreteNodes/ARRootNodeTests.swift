@testable import MapboxVisionAR
import simd
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

    func testARNodeAfterInitHasExpectedInitialPosition() {
        // Given
        let expectedInitialPosition = float3(0, 0, 0)

        // When // Then
        XCTAssertEqual(rootNode.position, expectedInitialPosition)
    }

    func testARNodeAfterInitHasExpectedInitialRotation() {
        // Given
        let expectedInitialRotation = simd_quatf()

        // When // Then
        XCTAssertEqual(rootNode.rotation, expectedInitialRotation)
    }

    func testARNodeAfterInitHasExpectedInitialScale() {
        // Given
        let expectedInitialScale = float3(1, 1, 1)

        // When // Then
        XCTAssertEqual(rootNode.scale, expectedInitialScale)
    }

    func testAddChildMethodAddsChildNodes() {
        // Given
        let expectedNumberOfChildNodes = Int.random(in: 1...10)

        // When
        for _ in 1...expectedNumberOfChildNodes {
            rootNode.add(child: ARCameraNode())
        }

        // Then
        XCTAssertEqual(rootNode.childs.count, expectedNumberOfChildNodes)
    }

    func testAddChildMethodDoNotAddARRootNodeAsAChildNode() {
        // Given state from setUp()
        let numberOfRootChildNodesTryingToAdd = Int.random(in: 1...10)
        // When
        for _ in 1...numberOfRootChildNodesTryingToAdd {
            rootNode.add(child: ARRootNode())
        }

        // Then
        XCTAssertTrue(rootNode.childs.isEmpty)
    }

    func testChildNodeHasParentAfterAddChildMethodExecution() {
        // Given
        let childNode = ARCameraNode()

        // When
        rootNode.add(child: childNode)
        XCTAssertNotNil(childNode.parent)
        XCTAssertTrue((childNode.parent as? ARNode) === rootNode)
    }

    func testRemoveAllChildsMethodRemovesChildNodes() {
        // Given
        for _ in 1...Int.random(in: 1...10) {
            rootNode.add(child: ARRootNode())
        }

        // When
        rootNode.removeAllChilds()

        // Then
        XCTAssertTrue(rootNode.childs.isEmpty)
    }

    func testWorldTransformMethodUpdatesWorldTransformWhenGeometryOfParentNodeChanges() {
        // Given
        let parentNode = ARRootNode()
        let childNode = ARCameraNode()
        let initialWorldTransform = childNode.worldTransform()

        parentNode.add(child: childNode)
        parentNode.geometry.position = float3(1, 1, 1)

        // When
        let finalState = childNode.worldTransform()

        // Then
        XCTAssertNotEqual(initialWorldTransform, finalState)
    }

    func testWorldTransformMethodDoesNotUpdateWorldTransformWhenGeometryOfChildNodeChanges() {
        // Given
        let parentNode = ARRootNode()
        let childNode = ARCameraNode()
        let initialWorldTransform = parentNode.worldTransform()

        parentNode.add(child: childNode)
        childNode.geometry.position = float3(1, 1, 1)

        // When
        let finalState = parentNode.worldTransform()

        // Then
        XCTAssertEqual(initialWorldTransform, finalState)
    }
}
