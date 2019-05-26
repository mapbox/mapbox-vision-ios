protocol VisionPresentationViewControllerInput {
    func enqueue(_ sampleBuffer: CMSampleBuffer)
    func present(fps: FPSValue?)
    func present(segmentation: FrameSegmentation)
    func present(detections: FrameDetections)
}
