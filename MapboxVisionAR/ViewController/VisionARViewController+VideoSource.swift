import MapboxVisionARNative

public extension VisionARViewController {
    func set(arManager: VisionARManager) {
        guard let native = arManager.native else { return }
        self.set(arManager: native)
    }
}
