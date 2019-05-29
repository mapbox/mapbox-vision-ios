import simd

struct ARLight {
    var color = float3(1, 1, 1)
    var position = float3(0, 0, 0)

    static func defaultLightForLane() -> ARLight {
        return ARLight(color: float3(1, 1, 1), position: float3(0, 7, 0))
    }
}
