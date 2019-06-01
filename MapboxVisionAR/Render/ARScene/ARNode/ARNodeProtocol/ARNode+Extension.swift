import simd

/// Properties common to the AR nodes which will be displayed in `ARScene`.
protocol ARNode: Node {
    /// Type of node.
    var nodeType: ARNodeType { get }
    /// Underlying AR entity.
    var entity: AREntity? { get }
}

extension ARNode {
    // MARK: - Properties

    ///  The node’s parent in the graph hierarchy. For a scene’s root node, the value of this property is nil.
    var parent: Node? {
        get { return relations.parent }
        set { relations.parent = newValue }
    }

    /// An array of the node's objects that are current node’s children in the scene graph hierarchy.
    var childs: [Node] {
        get { return relations.childs }
        set { relations.childs = newValue }
    }

    /**
     The position of node.

     The node’s position locates it within the coordinate system of its parent using three-component vector. The default position is the zero vector, indicating that the node is placed at the origin of the parent node’s coordinate system.
     */
    var position: float3 {
        get { return geometry.position }
        set { geometry.position = newValue }
    }

    /**
     The node’s orientation, expressed as a rotation angle about an axis.

     The four-component rotation vector specifies the direction of the rotation axis in the first three components and the angle of rotation (in radians) in the fourth. The default rotation is the zero vector, specifying no rotation.
     */
    var rotation: simd_quatf {
        get { return geometry.rotation }
        set { geometry.rotation = newValue }
    }

    /**
     The scale factor applied to the node.

     Each component of the scale vector multiplies the corresponding dimension of the node’s geometry. The default scale is 1.0 in all three dimensions. For example, applying a scale of (2.0, 0.5, 2.0) to a node containing a cube geometry reduces its height and increases its width and depth.
     */
    var scale: float3 {
        get { return geometry.scale }
        set { geometry.scale = newValue }
    }

    // MARK: - Functions

    /**
     Adds a node to the node’s array of children.

     Calling this method appends the node to the end of the `childs` array and create reference from child's property `parent`.

     - Parameters:
       - child: The node to be added.
     */
    func add(child: Node) {
        child.geometry.setNeedsTransformUpdate()
        childs.append(child)
        child.relations.parent = self
    }

    /**
     Removes all child nodes from the node’s array of children.

     Calling this method removes all nodes from `childs` array.
     */
    func removeAllChilds() {
        childs.removeAll()
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
