/// Methods and properties common to the nodes which can be a part of node hierarchy.
protocol Node: AnyObject {
    // MARK: - Properties

    /// The node’s parent in the graph hierarchy. For a scene’s root node, the value of this property is nil.
    var parent: Node? { get set }
    /// An array of the node's objects that are current node’s children in the scene graph hierarchy.
    var childNodes: [Node] { get set }
    /// Set of properties that determine the transformation between coordinate systems.
    var geometry: NodeGeometry { get set }

    // MARK: - Functions

    /**
     Adds a node to the node’s array of children.

     - Parameters:
       - child: The node to be added.
     */
    func add(child: Node)

    /**
     Removes all child nodes from the node’s array of children.
     */
    func removeAllChilds()
}
