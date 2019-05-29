import simd

class ARNode {
    // MARK: - Properties

    var entity: AREntity?
    var position = float3(0, 0, 0) {
        didSet {
            setNeedTranformUpdate()
        }
    }
    var rotation = simd_quatf() {
        didSet {
            setNeedTranformUpdate()
        }
    }
    var scale = float3(1, 1, 1) {
        didSet {
            setNeedTranformUpdate()
        }
    }

    var cachedTransformMatrix = matrix_identity_float4x4

    private(set) var childs = [ARNode]()
    private(set) var nodeType: ARNodeType = .generalNode

    // MARK: - Private properties

    private weak var parent: ARNode?
    private var needTransformUpdate = Bool(true)

    // MARK: - Lifecycle

    init(type: ARNodeType) {
        self.nodeType = type
    }

    // MARK: - Public functions

    func add(child: ARNode) {
        child.setNeedTranformUpdate()
        childs.append(child)
    }

    func removeAllChilds() {
        childs.removeAll()
    }

    func worldTransform() -> float4x4 {
        if needTransformUpdate {
            let localTransform = makeTransformMatrix(trans: position, rot: rotation, scale: scale)

            if let parent = parent {
                cachedTransformMatrix = parent.worldTransform() * localTransform
            } else {
                cachedTransformMatrix = localTransform
            }
            needTransformUpdate = false
        }

        return cachedTransformMatrix
    }

    // MARK: - Private functions

    private func setNeedTranformUpdate() {
        needTransformUpdate = true
    }
}
