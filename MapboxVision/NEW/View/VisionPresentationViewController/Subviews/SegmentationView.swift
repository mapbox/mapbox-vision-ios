import MetalKit

final class SegmentationView: MTKView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonViewInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonViewInit()
    }

    private func commonInit() {
        self.device = MTLCreateSystemDefaultDevice()
        self.translatesAutoresizingMaskIntoConstraints = false
        self.colorPixelFormat = .bgra8Unorm
        self.framebufferOnly = false
        self.autoResizeDrawable = false
        self.contentMode = .scaleAspectFill
        self.isHidden = true
        self.isPaused = true
        self.enableSetNeedsDisplay = false
    }
}
