import simd

struct DefaultVertexUniforms {
    var viewProjectionMatrix: float4x4
    var modelMatrix: float4x4
    var normalMatrix: float3x3
}

struct ArrowVertexUniforms {
    var viewProjectionMatrix: float4x4
    var modelMatrix: float4x4
    var normalMatrix: float3x3
    var p0: float3
    var p1: float3
    var p2: float3
    var p3: float3
}

struct FragmentUniforms {
    var cameraWorldPosition = float3(0, 0, 0)
    var ambientLightColor = float3(0, 0, 0)
    var specularColor = float3(1, 1, 1)
    var baseColor = float3(1, 1, 1)
    var opacity: Float = 1
    var specularPower: Float = 1
    var light = ARLight()
}

struct LaneFragmentUniforms {
    var baseColor = float4(1, 1, 1, 1)
}

struct LaneWidthUniforms {
    var width: Float
}
