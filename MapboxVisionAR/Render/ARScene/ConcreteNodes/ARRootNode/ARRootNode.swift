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
}
