import simd

protocol ARNode: Node {
    var nodeType: ARNodeType { get }
    var entity: AREntity? { get }
}

extension ARNode {
    var parent: Node? {
        get { return relations.parent }
        set { relations.parent = newValue }
    }

    var childs: [Node] {
        get { return relations.childs }
        set { relations.childs = newValue }
    }

    var position: float3 {
        get { return geometry.position }
        set { geometry.position = newValue }
    }

    var rotation: simd_quatf {
        get { return geometry.rotation }
        set { geometry.rotation = newValue }
    }

    var scale: float3 {
        get { return geometry.scale }
        set { geometry.scale = newValue }
    }

    func add(child: Node) {
        child.geometry.setNeedTransformUpdate()
        childs.append(child)
    }

    func removeAllChilds() {
        childs.removeAll()
    }

    func worldTransform() -> float4x4 {
        let localTransfrom = geometry.worldTransform()
        if let parent = parent {
            return parent.geometry.worldTransform() * localTransfrom
        } else {
            return localTransfrom
        }
    }
}
