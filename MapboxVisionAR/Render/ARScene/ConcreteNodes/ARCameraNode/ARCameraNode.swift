import simd

class ARCameraNode: ARNode {
    // MARK: - Properties

    /// Type of node. Always returns `cameraNode`.
    private(set) var nodeType: ARNodeType
    /// Underlying AR entity.
    var entity: AREntity?
    /// The node’s parent in the graph hierarchy. For a scene’s root node, the value of this property is nil.
    weak var parent: Node?
    /// An array of the node's objects that are current node’s children in the scene graph hierarchy.
    var childNodes: [Node]
    /// Describes transformation between coordinate systems.
    var geometry: NodeGeometry

    private(set) var cachedProjectionMatrix = float4x4()
    private(set) var needsUpdateProjection = true
    var nearClipPlane: Float = 0.01 {
        didSet {
            setNeedsUpdateProjection()
        }
    }
    var farClipPlane: Float = 1000 {
        didSet {
            setNeedsUpdateProjection()
        }
    }
    var fovRadians = degreesToRadians(60) {
        didSet {
            setNeedsUpdateProjection()
        }
    }
    var aspectRatio = Float(4.0 / 3.0) {
        didSet {
            setNeedsUpdateProjection()
        }
    }

    // MARK: - Lifecycle

    init() {
        nodeType = .cameraNode
        childNodes = []
        geometry = NodeGeometry()
    }

    // MARK: - Internal functions

    func frameSize(size: float2) {
        assert(size.y > 0)
        aspectRatio = size.x / size.y
    }

    func projectionMatrix() -> float4x4 {
        if needsUpdateProjection {
            needsUpdateProjection = false
            cachedProjectionMatrix = makePerpectiveProjectionMatrix(fovRadians: fovRadians, aspectRatio: aspectRatio, nearZ: nearClipPlane, farZ: farClipPlane)
        }

        return cachedProjectionMatrix
    }

    func setNeedsUpdateProjection() {
        needsUpdateProjection = true
    }
}
