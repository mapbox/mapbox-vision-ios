import MetalKit

class AREntity {
    // MARK: - Properties

    var mesh: MTKMesh?
    var material = ARMaterial()
    var renderPipeline: MTLRenderPipelineState?

    // MARK: - Lifecycle

    init(mesh: MTKMesh) {
        self.mesh = mesh
    }
}
