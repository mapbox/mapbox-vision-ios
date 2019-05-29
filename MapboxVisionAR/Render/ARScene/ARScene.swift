import MetalKit
import simd

class ARNode {
    private weak var parent: ARNode?
    private(set) var childs = [ARNode]()

    private var name: String?
    private var needTransformUpdate = Bool(true)

    var entity: AREntity?
    var position = float3(0, 0, 0) {
        didSet {
            requireTranformUpdate()
        }
    }

    var rotation = simd_quatf() {
        didSet {
            requireTranformUpdate()
        }
    }

    var scale = float3(1, 1, 1) {
        didSet {
            requireTranformUpdate()
        }
    }

    var cachedTransformMatrix = matrix_identity_float4x4

    init(name: String) {
        self.name = name
    }

    func add(child: ARNode) {
        child.requireTranformUpdate()
        childs.append(child)
    }

    private func requireTranformUpdate() {
        needTransformUpdate = true
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
}

class ARCameraNode: ARNode {
    var needProjectionUpdate = Bool(true)
    var nearClipPlane = Float(0.01) {
        didSet {
            requestProjectionUpdate()
        }
    }

    var farClipPlane = Float(1000) {
        didSet {
            requestProjectionUpdate()
        }
    }

    var fovRadians = degreesToRadians(60) {
        didSet {
            requestProjectionUpdate()
        }
    }

    var aspectRatio = Float(1.333) {
        didSet {
            requestProjectionUpdate()
        }
    }

    private var cachedProjectionMatrix = float4x4()

    init() {
        super.init(name: "Camera")
    }

    func frameSize(size: float2) {
        assert(size.y > 0)
        aspectRatio = size.x / size.y
    }

    private func requestProjectionUpdate() {
        needProjectionUpdate = true
    }

    func projectionMatrix() -> float4x4 {
        if needProjectionUpdate {
            needProjectionUpdate = false
            cachedProjectionMatrix = makePerpectiveProjectionMatrix(fovRadians: fovRadians, aspectRatio: aspectRatio, nearZ: nearClipPlane, farZ: farClipPlane)
        }

        return cachedProjectionMatrix
    }
}

class ARScene {
    var rootNode = ARNode(name: "root")
    var camera = ARCameraNode()
}
