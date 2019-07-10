/**
 Represents parameters to configure look and feel of AR lane.
 */
public struct LaneVisualParams {
    /// Color of the lane represented in RGBA. It takes alpha channel into account.
    public var color = UIColor(red: CGFloat(ARConstants.laneDefaultColor.x),
                        green: CGFloat(ARConstants.laneDefaultColor.y),
                        blue: CGFloat(ARConstants.laneDefaultColor.z),
                        alpha: CGFloat(ARConstants.laneDefaultColor.w))
    /// Width of the lane in meters.
    public var width: Float = 1.0
    /// Position of the light source.
    public var lightPosition = WorldCoordinate(x: 0, y: 0, z: 0)
    /// Color of the light source. It does not take alpha channel into account.
    public var lightColor = UIColor.white
    /// Ambient light color represented in RGB. It does not take alpha channel into account.
    public var ambientColor = UIColor(red: CGFloat(ARConstants.laneDefaultColor.x),
                               green: CGFloat(ARConstants.laneDefaultColor.y),
                               blue: CGFloat(ARConstants.laneDefaultColor.z),
                               alpha: 1.0)
}
