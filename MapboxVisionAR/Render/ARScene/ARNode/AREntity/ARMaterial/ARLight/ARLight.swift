import simd

/**
 Describes a light source that can be attached to a node to illuminate the scene.
 */
struct ARLight {
    // MARK: - Properties

    /// Color of light.
    var color = float3(1, 1, 1)
    /// Position of light source.
    var position = float3(0, 0, 0)

    // MARK: - Functions

    /**
     Get default light object for AR lane.

     - Returns:
     */
    static func defaultLightForLane() -> ARLight {
        return ARLight(color: float3(1, 1, 1), position: float3(0, 7, 0))
    }
}
