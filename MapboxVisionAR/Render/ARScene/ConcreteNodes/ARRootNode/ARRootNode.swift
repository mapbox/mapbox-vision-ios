class ARRootNode: ARNode {
    private(set) var nodeType: ARNodeType
    var entity: AREntity?
    var relations: NodeRelations
    var geometry: NodeGeometry

    init() {
        nodeType = .rootNode
        relations = NodeRelations()
        geometry = NodeGeometry()
    }
}
