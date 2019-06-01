import simd

class ARCameraNode: ARNode {
    // MARK: - Properties

    /// Type of node. Always returns `rootNode`.
    private(set) var nodeType: ARNodeType
    /// Underlying AR entity.
    var entity: AREntity?
    /// Describes position of the node in the node hierarchy.
    var relations: NodeRelations
    /// Describes transformation between coordinate systems.
    var geometry: NodeGeometry

    var needProjectionUpdate = true
    var nearClipPlane: Float = 0.01 {
        didSet {
            setNeedProjectionUpdate()
        }
    }
    var farClipPlane: Float = 1000 {
        didSet {
            setNeedProjectionUpdate()
        }
    }
    var fovRadians = degreesToRadians(60) {
        didSet {
            setNeedProjectionUpdate()
        }
    }
    var aspectRatio = Float(4.0 / 3.0) {
        didSet {
            setNeedProjectionUpdate()
        }
    }

    // MARK: - Private properties

    private(set) var cachedProjectionMatrix = float4x4()

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

    func setNeedProjectionUpdate() {
        needProjectionUpdate = true
    }
}
