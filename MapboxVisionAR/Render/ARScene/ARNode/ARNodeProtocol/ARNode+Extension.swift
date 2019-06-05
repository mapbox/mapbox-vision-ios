import simd

/// Properties common to the AR nodes which will be displayed in `ARScene`.
protocol ARNode: Node {
    /// Type of node.
    var nodeType: ARNodeType { get }
    /// Underlying AR entity.
    var entity: AREntity? { get }
}

extension ARNode {
    // MARK: - Functions

    /**
     Adds a node to the node’s array of children.

     Calling this method appends the node to the end of the `childs` array and create reference from child's property `parent`.

     - Parameters:
       - childNode: The node to be added.
     */
    func add(childNode: Node) {
        childNode.geometry.setNeedsTransformUpdate()
        childNodes.append(childNode)
        childNode.parent = self
    }

    /**
     Removes all child nodes from the node’s array of children.

     Calling this method removes all nodes from `childs` array.
     */
    func removeAllChilds() {
        childNodes.removeAll()
    }

    /**
     Updates world transform matrix and returns updated value, relative to the scene coordinate space.

     A world transform is the node’s coordinate space transform relative to the scene’s coordinate space. This transform is the concatenation of the node’s transform property with that of its parent node, the parent’s parent, and so on up to the rootNode object of the scene.

     - Returns: The updated world transform applied to the node.
     */
    func worldTransform() -> float4x4 {
        let localTransfrom = geometry.worldTransform()
        if let parent = parent {
            return parent.geometry.worldTransform() * localTransfrom
        } else {
            return localTransfrom
        }
    }
}
