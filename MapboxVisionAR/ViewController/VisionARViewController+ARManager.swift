import MapboxVisionARNative

public extension VisionARViewController {
    /**
     Set AR Manager for AR view.

     - Parameters:
     - arManager: instance of VisinARManager
     */
    func set(arManager: VisionARManager) {
        guard let native = arManager.native else { return }
        self.set(arManager: native)
    }
}
