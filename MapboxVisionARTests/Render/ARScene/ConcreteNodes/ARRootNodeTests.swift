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
        XCTAssertEqual(rootNode.geometry.position, expectedInitialPosition)
    }

    func testARNodeAfterInitHasExpectedInitialRotation() {
        // Given
        let expectedInitialRotation = simd_quatf()

        // When // Then
        XCTAssertEqual(rootNode.geometry.rotation, expectedInitialRotation)
    }

    func testARNodeAfterInitHasExpectedInitialScale() {
        // Given
        let expectedInitialScale = float3(1, 1, 1)

        // When // Then
        XCTAssertEqual(rootNode.geometry.scale, expectedInitialScale)
    }

    func testAddChildMethodAddsChildNodes() {
        // Given
        let expectedNumberOfChildNodes = Int.random(in: 1...10)

        // When
        for _ in 1...expectedNumberOfChildNodes {
            rootNode.add(childNode: ARCameraNode())
        }

        // Then
        XCTAssertEqual(rootNode.childNodes.count, expectedNumberOfChildNodes)
    }

    func testAddChildMethodDoNotAddARRootNodeAsAChildNode() {
        // Given state from setUp()
        let numberOfRootChildNodesTryingToAdd = Int.random(in: 1...10)

        // When
        for _ in 1...numberOfRootChildNodesTryingToAdd {
            rootNode.add(childNode: ARRootNode())
        }

        // Then
        XCTAssertTrue(rootNode.childNodes.isEmpty)
    }

    func testChildNodeHasParentAfterAddChildMethodExecution() {
        // Given
        let childNode = ARCameraNode()

        // When
        rootNode.add(childNode: childNode)

        // Then
        XCTAssertNotNil(childNode.parent)
        XCTAssertTrue((childNode.parent as? ARNode) === rootNode)
    }

    func testRemoveAllChildsMethodRemovesChildNodes() {
        // Given
        for _ in 1...Int.random(in: 1...10) {
            rootNode.add(childNode: ARRootNode())
        }

        // When
        rootNode.removeAllChilds()

        // Then
        XCTAssertTrue(rootNode.childNodes.isEmpty)
    }

    func testWorldTransformMethodUpdatesWorldTransformWhenGeometryOfParentNodeChanges() {
        // Given
        let parentNode = ARRootNode()
        let childNode = ARCameraNode()
        let initialWorldTransform = childNode.worldTransform()

        parentNode.add(childNode: childNode)

        // When
        parentNode.geometry.position = float3(1, 1, 1)

        // Then
        let finalState = childNode.worldTransform()
        XCTAssertNotEqual(initialWorldTransform, finalState)
    }

    func testWorldTransformMethodDoesNotUpdateWorldTransformWhenGeometryOfChildNodeChanges() {
        // Given
        let parentNode = ARRootNode()
        let childNode = ARCameraNode()
        let initialWorldTransform = parentNode.worldTransform()

        parentNode.add(childNode: childNode)

        // When
        childNode.geometry.position = float3(1, 1, 1)

        // Then
        let finalState = parentNode.worldTransform()
        XCTAssertEqual(initialWorldTransform, finalState)
    }
}
