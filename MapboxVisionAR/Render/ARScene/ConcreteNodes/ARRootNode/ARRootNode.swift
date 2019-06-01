/**
 Common root node in `ARScene`'s hierarchy.

 All scene content—nodes, geometries and their materials, lights, cameras, and related objects-are organized in a node hierarchy with a single common root node.
 Each child node’s coordinate system is defined relative to the transformation of its parent node.
 */
class ARRootNode: ARNode {
    // MARK: - Properties

    /// Type of node. Always returns `rootNode`.
    private(set) var nodeType: ARNodeType
    /// Underlying AR entity.
    var entity: AREntity?
    /// Describes position of the node in the node hierarchy.
    var relations: NodeRelations
    /// Describes transformation between coordinate systems.
    var geometry: NodeGeometry

    // MARK: - Lifecycle

    /**
     Creates instance of `ARRootNode` class.
     */
    init() {
        nodeType = .rootNode
        relations = NodeRelations()
        geometry = NodeGeometry()
    }

    /**
     Adds a node to the node’s array of children.

     Calling this method appends the node to the end of the `childs` array and create reference from child's property `parent`.
     Method do nothing if `child` node has `rootNode` type.

     - Parameters:
     - child: The node to be added.
     */
    func add(child: Node) {
        if let child = (child as? ARNode) {
            if child.nodeType == .rootNode {
                return
            }
        }

        child.geometry.setNeedsTransformUpdate()
        childs.append(child)
        child.relations.parent = self
    }
}
