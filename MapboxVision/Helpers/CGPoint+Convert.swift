import CoreGraphics
import Foundation

public extension CGPoint {

    /**
        Convert point with respect of aspect ratio
     
        - Parameter from: Original frame size
        - Parameter to: Destination frame size
        - Returns: Point converted with respect of aspect ratio
    */

    func convertForAspectRatioFill(from: CGSize, to: CGSize) -> CGPoint {

        let fromAspect = from.width / from.height
        let toAspect = to.width / to.height

        if fromAspect > toAspect {

            /*
             horizontal offset (scale with height)
             
             +------------+
             |//|      |//|
             |//|      |//| <- horizontal offset
             |//|      |//|
             +------------+
             
            */

            let scaleFactor = to.height / from.height
            let width = from.width * scaleFactor
            let offset = (width - to.width) / 2

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

            let scaleFactor = to.width / from.width
            let height = from.height * scaleFactor
            let offset = (height - to.height) / 2

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

            let scaleFactor = to.width / from.width

            return CGPoint(x: Int(x * scaleFactor), y: Int(y * scaleFactor))
        }
    }
}
