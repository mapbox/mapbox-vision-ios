import MapboxVisionNative

extension VisionPresentationViewController {
    public func set(visionManager: VisionManagerProtocol) {
        self.set(visionManager: visionManager.native)
    }
}
