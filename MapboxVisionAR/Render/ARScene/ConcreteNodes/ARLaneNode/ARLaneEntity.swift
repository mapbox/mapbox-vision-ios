import simd

class ARLaneEntity: AREntity {
    init(with arLaneMesh: ARLaneMesh, and renderPipelineState: MTLRenderPipelineState) {
        super.init(mesh: arLaneMesh.mtkMesh)
        self.material.diffuseColor = ARConstants.ARLaneDefaultColor
        self.material.specularPower = 100
        self.material.specularColor = float3(1, 1, 1)
        self.material.ambientLightColor = ARConstants.ARLaneDefaultColor.xyz
        self.renderPipeline = renderPipelineState
    }
}
