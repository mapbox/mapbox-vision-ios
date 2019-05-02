//
//  Created by Maksim on 3/15/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation

/**
     Interface that user’s custom object should conform to in order to receive events from `VisionARManager`.
     Delegate methods are called one by one followed by `visionManagerDidCompleteUpdate` call on a delegate of `VisionManager`.
 
     - NOTE: All delegate methods are called on a background thread.
*/
public protocol VisionARManagerDelegate: class {
    
    /**
        Tells the delegate that AR camera was updated.
    */
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARCamera camera: ARCamera)
    
    /**
        Tells the delegate that AR lane was updated.
    */
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARLane lane: ARLane?)
}

public extension VisionARManagerDelegate {
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARCamera camera: ARCamera) {}
    
    func visionARManager(_ visionARManager: VisionARManager, didUpdateARLane lane: ARLane?) {}
}
