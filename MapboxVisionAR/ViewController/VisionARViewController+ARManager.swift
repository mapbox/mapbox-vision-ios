import MapboxVisionARNative

public extension VisionARViewController {
    /**
     Set AR Manager for AR view.

     - Parameters:
     - arManager: instance of VisinARManager
     */
    func set(arManager: VisionARManager?) {
        self.set(arManager: arManager?.native)
    }
}
