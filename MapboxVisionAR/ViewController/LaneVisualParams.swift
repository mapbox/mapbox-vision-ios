/**
 Represents parameters to configure look and feel of AR lane.
 */
public struct LaneVisualParams {
    /// Color of the lane represented in RGBA. It takes alpha channel into account.
    var color: UIColor
    /// Width of the lane.
    var width: Float
    /// Position of the light source.
    var lightPosition: WorldCoordinate
    /// Color of the light source. It does not take alpha channel into account.
    var lightColor: UIColor
    /// Ambient light color represented in RGB. It does not take alpha channel into account.
    var ambientColor: UIColor

    init() {
        color = UIColor(red: CGFloat(ARConstants.laneDefaultColor.x),
                        green: CGFloat(ARConstants.laneDefaultColor.y),
                        blue: CGFloat(ARConstants.laneDefaultColor.z),
                        alpha: CGFloat(ARConstants.laneDefaultColor.w))
        width = 1.0
        lightPosition = WorldCoordinate(x: 0, y: 0, z: 0)
        lightColor = UIColor.white
        ambientColor = UIColor(red: CGFloat(ARConstants.laneDefaultColor.x),
                               green: CGFloat(ARConstants.laneDefaultColor.y),
                               blue: CGFloat(ARConstants.laneDefaultColor.z),
                               alpha: 1.0)
    }
}
