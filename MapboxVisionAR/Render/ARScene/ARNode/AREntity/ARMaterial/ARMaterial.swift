import simd

/// A set of shading attributes that define the appearance of a geometry's surface when rendered.
struct ARMaterial {
    /// Material’s base color represented in RGBA.
    var diffuseColor = ARConstants.ARLaneDefaultColor
    /// Ambient light color represented in RGB.
    var ambientLightColor = ARConstants.ARLaneDefaultColor.xyz
    /// Texture for coloring material.
    var colorTexture: MTLTexture?
    /// Light source for material.
    var light: ARLight?
    /// The color of light reflected directly toward the viewer from the surface of a geometry using the material.
    var specularColor = float3(1, 1, 1)
    /// The quantity that controls how “tight” the highlight is.
    /// A low specular power creates very broad highlights, while a high specular power creates pinpoint highlights.
    var specularPower: Float = 100
    /// The vertex winding mode.
    var frontFaceMode = MTLWinding.counterClockwise
}
