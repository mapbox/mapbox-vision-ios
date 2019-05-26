extension VisionManager: RecordCoordinatorDelegate {
    func recordingStarted(path: String) {}

    func recordingStopped() {
        trySync()
    }
}
