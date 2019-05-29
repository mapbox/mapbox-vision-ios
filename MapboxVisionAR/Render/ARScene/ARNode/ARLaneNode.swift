import simd

class ARLaneNode: ARNode  {
    // MARK: - Lifecycle

    init(arLaneEntity: ARLaneEntity) {
        super.init(type: .arrowNode)
        self.entity = arLaneEntity
    }

    // MARK: - Public methods

    //    RGBA color of a lane
    func set(laneColor: UIColor) {
        if let (red, green, blue, alpha) = laneColor.rgbaComponents() {
            let newARLaneColor = float4(Float(red),
                                        Float(green),
                                        Float(blue),
                                        Float(alpha))
            self.entity?.material.diffuseColor = newARLaneColor
        }
    }

    // width of lane in meter
    func set(laneWidth: Float) {
        self.scale.x = laneWidth
    }

    // position of light source // TODO: update doc comments and fix in docs
    func set(light: ARLight) {
        self.entity?.material.light = light
    }

    // RGBA color of a light source
    func set(laneLightColor: UIColor) {
        if let (red, green, blue) = laneLightColor.rgbComponents() {
            let newLaneLightColor = float3(Float(red),
                                           Float(green),
                                           Float(blue))
            self.entity?.material.light?.color = newLaneLightColor
        }
    }

    // ambient color
    func set(laneAmbientColor: UIColor) {
        if let (red, green, blue) = laneAmbientColor.rgbComponents() {
            let newAmbientLightColor = float3(Float(red),
                                              Float(green),
                                              Float(blue))
            self.entity?.material.ambientLightColor = newAmbientLightColor
        }
    }
}
