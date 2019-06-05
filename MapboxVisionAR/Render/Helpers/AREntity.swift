import MetalKit

/**
 `AREntity` allows to more easily manage complex object graphs.
 Basically it contains node-specific details.
 */
class AREntity {
    // MARK: - Properties

    /// A container for the vertex data suitable for use in a Metal app.
    var mesh: MTKMesh?
    /// Defines the appearance of a geometry's surface when rendered.
    var material = ARMaterial()
    /// An object that contains the graphics functions and configuration state used in a render pass.
    var renderPipeline: MTLRenderPipelineState?

    // MARK: - Lifecycle

    /**
     Creates instance of `AREntity` class

     - Parameters:
       - mesh: Mesh suitable for use with Metal API.
     */
    init(mesh: MTKMesh) {
        self.mesh = mesh
    }
}
