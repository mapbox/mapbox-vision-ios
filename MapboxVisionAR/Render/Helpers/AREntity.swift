import MetalKit

/**
 `AREntity` allows to more easily manage complex object graphs in your game.
 Basically it contains node-specific details.
 */
class AREntity {
    // MARK: - Properties

    ///
    var mesh: MTKMesh?
    /// Defines the appearance of a geometry's surface when rendered.
    var material = ARMaterial()
    ///
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
