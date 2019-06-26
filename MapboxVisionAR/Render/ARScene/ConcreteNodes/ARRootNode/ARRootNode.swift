/**
 Common root node in `ARScene`'s hierarchy.

 All scene content—nodes, geometries and their materials, lights, cameras, and related objects-are organized in a node hierarchy with a single common root node.
 Each child node’s coordinate system is defined relative to the transformation of its parent node.
 */
class ARRootNode: ARNode {
    // MARK: - Lifecycle

    /**
     Creates an instance of `ARRootNode` class.
     The instance has `root` type.
     */
    init() {
        super.init(with: .root)
    }
}
