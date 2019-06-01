import simd

/**
 Implementation of `AREntity` for AR lane.
 */
class ARLaneEntity: AREntity {
    /**
     Creates instance of `ARLaneEntity` class.

     - Parameters:
       - arLaneMesh: mesh for AR lane.
       - renderPipelineState: Object that holds the graphics functions and configuration state used in a render pass to draw AR lane.
     */
    init(with arLaneMesh: ARLaneMesh, and renderPipelineState: MTLRenderPipelineState) {
        super.init(mesh: arLaneMesh.mtkMesh)
        self.material.diffuseColor = ARConstants.ARLaneDefaultColor
        self.material.specularPower = 100
        self.material.specularColor = float3(1, 1, 1)
        self.material.ambientLightColor = ARConstants.ARLaneDefaultColor.xyz
        self.renderPipeline = renderPipelineState
    }
}
