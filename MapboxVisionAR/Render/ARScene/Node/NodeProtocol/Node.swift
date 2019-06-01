/// Methods and properties common to the nodes which can be a part of node hierarchy.
protocol Node: AnyObject {
    // MARK: - Properties

    /// Set of properties describing position of the node in the node hierarchy.
    var relations: NodeRelations { get set }
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
