import simd

/// Represents AR Lane that can be rendered as a part of `ARScene`
class ARLaneNode: ARNode {
    // MARK: - Lifecycle

    init(arLaneEntity: ARLaneEntity) {
        super.init(type: .arrowNode)
        self.entity = arLaneEntity
    }

    // MARK: - Public methods

    /**
     Set new color for underlying AR Lane.

     Method do nothing if `laneColor` does not have compatible color space
     or there's no underlying AR lane's representation.

     - Parameters:
       - laneColor: New color of AR lane. It must be in RGBA color space.
     */
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

    /**
     Set new color of a light source for AR lane.

     Method do nothing if `laneLightColor` does not have compatible color space
     or there's no underlying AR lane's representation.

     - Parameters:
       - laneLightColor: New color of a light source for AR lane. It must be in RGB color space.
     */
    func set(laneLightColor: UIColor) {
        if let (red, green, blue) = laneLightColor.rgbComponents() {
            let newLaneLightColor = float3(Float(red),
                                           Float(green),
                                           Float(blue))
            self.entity?.material.light?.color = newLaneLightColor
        }
    }

    /**
     Set new ambient color for AR lane.

     Method do nothing if `laneAmbientColor` does not have compatible color space
     or there's no underlying AR lane's representation.

     - Parameters:
       - laneAmbientColor: New ambient color for AR lane. It must be in RGB color space.
     */
    func set(laneAmbientColor: UIColor) {
        if let (red, green, blue) = laneAmbientColor.rgbComponents() {
            let newAmbientLightColor = float3(Float(red),
                                              Float(green),
                                              Float(blue))
            self.entity?.material.ambientLightColor = newAmbientLightColor
        }
    }
}
