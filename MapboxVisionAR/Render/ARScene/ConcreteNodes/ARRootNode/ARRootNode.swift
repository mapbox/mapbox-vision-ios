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
    /// The node’s parent in the graph hierarchy. For a scene’s root node, the value of this property is nil.
    weak var parent: Node?
    /// An array of the node's objects that are current node’s children in the scene graph hierarchy.
    var childNodes: [Node]
    /// Describes transformation between coordinate systems.
    var geometry: NodeGeometry

    // MARK: - Lifecycle

    /**
     Creates instance of `ARRootNode` class.
     */
    init() {
        nodeType = .rootNode
        childNodes = []
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
        childNodes.append(child)
        child.parent = self
    }
}
