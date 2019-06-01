/**
 A customn container for the node hierarchy and global properties.
 Together they are used to form a displayable AR scene.
 */
class ARScene {
    // MARK: - Properties

    /// The root node of the scene graph
    var rootNode = ARRootNode()

    /// Node with a set of camera attributes to provide a point of view for displaying the scene
    var cameraNode = ARCameraNode()

    // MARK: - Public methods

    /**
     Returns all `ARLaneNode` nodes in the root’s child node subtree.

     - Returns: An array containing `ARLaneNode` nodes.
     */
    func getChildARLaneNodes() -> [ARLaneNode] {
        return rootNode.childs.compactMap { $0 as? ARLaneNode }
    }
}
