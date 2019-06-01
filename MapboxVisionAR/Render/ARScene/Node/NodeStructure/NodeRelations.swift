/**
 The node in scene is a part of node hierarchy.
 The current structure represents node's position in the hierarchy.
 */
struct NodeRelations {
    /// The node’s parent in the graph hierarchy. For a scene’s root node, the value of this property is nil.
    weak var parent: Node?
    /// An array of the node's objects that are current node’s children in the scene graph hierarchy.
    var childs = [Node]()
}
