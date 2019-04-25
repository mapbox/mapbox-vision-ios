import CoreGraphics
import Foundation

public extension CGPoint {
    /**
        Convert point with respect of aspect ratio
     
        - Parameter from: Original frame size
        - Parameter to: Destination frame size
        - Returns: Point converted with respect of aspect ratio
    */

    func convertForAspectRatioFill(from original: CGSize, to destination: CGSize) -> CGPoint {
        let fromAspect = original.width / original.height
        let toAspect = destination.width / destination.height

        if fromAspect > toAspect {
            /*
             horizontal offset (scale with height)
             
             +------------+
             |//|      |//|
             |//|      |//| <- horizontal offset
             |//|      |//|
             +------------+
             
            */

            let scaleFactor = destination.height / original.height
            let width = original.width * scaleFactor
            let offset = (width - destination.width) / 2

            return CGPoint(x: Int((x * scaleFactor) - offset), y: Int(y * scaleFactor))
        } else if fromAspect < toAspect {
            /*
            vertical offset (scale with width)
             
             +------------+
             |////////////| <- vertical offset
             +------------+
             |            |
             |            |
             +------------+
             |////////////|
             +------------+
 
            */

            let scaleFactor = destination.width / original.width
            let height = original.height * scaleFactor
            let offset = (height - destination.height) / 2

            return CGPoint(x: Int(x * scaleFactor), y: Int((y * scaleFactor) - offset))
        } else {
            /*
            proportional scale
 
             +------------+
             |            |
             |            |
             |            |
             |            |
             +------------+
             
            */

            let scaleFactor = destination.width / original.width

            return CGPoint(x: Int(x * scaleFactor), y: Int(y * scaleFactor))
        }
    }
}
