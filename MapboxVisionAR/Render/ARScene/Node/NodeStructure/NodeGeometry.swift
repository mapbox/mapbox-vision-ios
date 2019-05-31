import simd

struct NodeGeometry {
    var position = float3(0, 0, 0) {
        didSet { setNeedTransformUpdate() }
    }
    var rotation = simd_quatf() {
        didSet { setNeedTransformUpdate() }
    }
    var scale = float3(1, 1, 1) {
        didSet { setNeedTransformUpdate() }
    }

    var needTransformUpdate = true
    var cachedTransformMatrix = matrix_identity_float4x4

    mutating func worldTransform() -> float4x4 {
        if needTransformUpdate {
            cachedTransformMatrix = makeTransformMatrix(trans: position, rot: rotation, scale: scale)
            needTransformUpdate = false
        }

        return cachedTransformMatrix
    }

    mutating func setNeedTransformUpdate() {
        needTransformUpdate = true
    }
}
