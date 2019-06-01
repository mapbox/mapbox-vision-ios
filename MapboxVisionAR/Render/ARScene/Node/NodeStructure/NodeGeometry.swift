import simd

/**
 The root object in AR scene defines the coordinate system of the world rendered by rendering engine.
 Each child node you add to this root node creates its own coordinate system, which is in turn inherited by its own children.
 You determine the transformation between coordinate systems using properties of this structure.
 */
struct NodeGeometry {
    // MARK: - Properties

    /**
     The position of node.

     The node’s position locates it within the coordinate system of its parent using three-component vector. The default position is the zero vector, indicating that the node is placed at the origin of the parent node’s coordinate system.
     */
    var position = float3(0, 0, 0) {
        didSet { setNeedTransformUpdate() }
    }

    /**
     The node’s orientation, expressed as a rotation angle about an axis.

     The four-component rotation vector specifies the direction of the rotation axis in the first three components and the angle of rotation (in radians) in the fourth. The default rotation is the zero vector, specifying no rotation.
     */
    var rotation = simd_quatf() {
        didSet { setNeedTransformUpdate() }
    }

    /**
     The scale factor applied to the node.

     Each component of the scale vector multiplies the corresponding dimension of the node’s geometry. The default scale is 1.0 in all three dimensions. For example, applying a scale of (2.0, 0.5, 2.0) to a node containing a cube geometry reduces its height and increases its width and depth.
     */
    var scale = float3(1, 1, 1) {
        didSet { setNeedTransformUpdate() }
    }

    /// Marks the world transorm as needing to be recalculated.
    private(set) var needTransformUpdate = true
    /// The world transform applied to the node.
    private(set) var cachedTransformMatrix = matrix_identity_float4x4

    // MARK: - Functions

    /**
     Updates world transform matrix and returns updated value.

     - Returns: Updated world transform matrix.
     */
    mutating func worldTransform() -> float4x4 {
        if needTransformUpdate {
            cachedTransformMatrix = makeTransformMatrix(trans: position, rot: rotation, scale: scale)
            needTransformUpdate = false
        }

        return cachedTransformMatrix
    }

    /**
     Marks the world transform as needing to be recalculated.

     You can use this method or the to notify the `ARScene` that your node has updated coordinates and world transform is need to be redrawn. This method makes a note of the request and returns immediately. The value is not actually recalculated until the next render cycle, at which point all invalidated world transforms are updated.
     */
    mutating func setNeedTransformUpdate() {
        needTransformUpdate = true
    }
}
