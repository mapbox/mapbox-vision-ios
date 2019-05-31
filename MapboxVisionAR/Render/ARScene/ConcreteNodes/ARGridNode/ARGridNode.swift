class ARGridNode: ARNode {
    private(set) var nodeType: ARNodeType
    var entity: AREntity?
    var relations: NodeRelations
    var geometry: NodeGeometry

    init() {
        nodeType = .gridNode
        relations = NodeRelations()
        geometry = NodeGeometry()
    }
}
