import simd

class ARCameraNode: ARNode {
    // MARK: - Properties

    private(set) var nodeType: ARNodeType
    var entity: AREntity?
    var relations: NodeRelations
    var geometry: NodeGeometry

    var needProjectionUpdate = Bool(true)
    var nearClipPlane = Float(0.01) {
        didSet {
            setNeedProjectionUpdate()
        }
    }
    var farClipPlane = Float(1000) {
        didSet {
            setNeedProjectionUpdate()
        }
    }
    var fovRadians = degreesToRadians(60) {
        didSet {
            setNeedProjectionUpdate()
        }
    }
    var aspectRatio = Float(1.333) {
        didSet {
            setNeedProjectionUpdate()
        }
    }

    // MARK: - Private properties

    private var cachedProjectionMatrix = float4x4()

    // MARK: - Lifecycle

    init() {
        nodeType = .cameraNode
        relations = NodeRelations()
        geometry = NodeGeometry()
    }

    // MARK: - Internal functions

    func frameSize(size: float2) {
        assert(size.y > 0)
        aspectRatio = size.x / size.y
    }

    func projectionMatrix() -> float4x4 {
        if needProjectionUpdate {
            needProjectionUpdate = false
            cachedProjectionMatrix = makePerpectiveProjectionMatrix(fovRadians: fovRadians, aspectRatio: aspectRatio, nearZ: nearClipPlane, farZ: farClipPlane)
        }

        return cachedProjectionMatrix
    }

    // MARK: - Private functions

    private func setNeedProjectionUpdate() {
        needProjectionUpdate = true
    }
}
