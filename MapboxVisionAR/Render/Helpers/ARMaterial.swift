import simd

struct ARMaterial {
    var ambientLightColor = float3(0, 0, 0)
    var diffuseColor = float4(1, 1, 1, 1)
    var colorTexture: MTLTexture?
    var light: ARLight?
    var specularColor = float3(1, 1, 1)
    var specularPower = Float(1)
    var frontFaceMode = MTLWinding.counterClockwise
}
