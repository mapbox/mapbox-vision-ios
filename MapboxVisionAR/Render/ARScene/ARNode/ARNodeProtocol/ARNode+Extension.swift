import simd

protocol ARNode: Node {
    var nodeType: ARNodeType { get }
    var entity: AREntity? { get }
}

extension ARNode {
    // MARK: - Properties

    /// The node’s parent in the scene graph hierarchy.
    var parent: Node? {
        get { return relations.parent }
        set { relations.parent = newValue }
    }

    /// An array of the node’s children in the scene graph hierarchy.
    var childs: [Node] {
        get { return relations.childs }
        set { relations.childs = newValue }
    }

    var position: float3 {
        get { return geometry.position }
        set { geometry.position = newValue }
    }

    var rotation: simd_quatf {
        get { return geometry.rotation }
        set { geometry.rotation = newValue }
    }

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
        child.geometry.setNeedTransformUpdate()
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

    func worldTransform() -> float4x4 {
        let localTransfrom = geometry.worldTransform()
        if let parent = parent {
            return parent.geometry.worldTransform() * localTransfrom
        } else {
            return localTransfrom
        }
    }
}
