protocol Node: AnyObject {
    var relations: NodeRelations { get set }
    var geometry: NodeGeometry { get set }

    func add(child: Node)
    func removeAllChilds()
}
