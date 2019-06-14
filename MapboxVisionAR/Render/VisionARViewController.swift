import CoreMedia
import Foundation
import MapboxVision
import MapboxVisionARNative
import MetalKit
import UIKit

/**
 Class that represents visual component that renders video stream from the camera and AR navigation route on top of that.
 */
public class VisionARViewController: UIViewController {
    /**
     Control the visibility of the Mapbox logo.
     */
    public var isLogoVisible: Bool {
        get {
            return !logoView.isHidden
        }
        set {
            logoView.isHidden = !newValue
        }
    }

    private var renderer: ARRenderer?
    /**
     Create an instance of VisionARNavigationController.
     */
    public init() {
        super.init(nibName: nil, bundle: nil)

        guard let device = MTLCreateSystemDefaultDevice() else {
            assertionFailure("Can't create Metal device")
            return
        }

        arView.device = device

        do {
            try renderer = ARRenderer(device: device,
                                      colorPixelFormat: arView.colorPixelFormat,
                                      depthStencilPixelFormat: arView.depthStencilPixelFormat)
            renderer?.initScene()
            arView.delegate = renderer
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    /// :nodoc:
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /**
     Display sample buffer (e.g. taken from `VideoSource`).
     */
    public func present(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        renderer?.frame = pixelBuffer
    }

    /**
     Set AR camera.
     */
    public func present(camera: ARCamera) {
        renderer?.camera = camera
    }

    /**
     Display AR lane.
     */
    public func present(lane: ARLane?) {
        renderer?.lane = lane
    }

    /// :nodoc:
    override public func viewDidLoad() {
        super.viewDidLoad()
        addChildView(arView)

        view.addSubview(logoView)
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: logoView.bottomAnchor, multiplier: 1),
            view.safeAreaLayoutGuide.rightAnchor.constraint(equalToSystemSpacingAfter: logoView.rightAnchor, multiplier: 1),
        ])
    }

    private func addChildView(_ childView: UIView) {
        childView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childView)

        NSLayoutConstraint.activate([
            childView.topAnchor.constraint(equalTo: view.topAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private let logoView: UIView = {
        let view = UIImageView(image: VisionImages.logo.image)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0.5
        return view
    }()

    private let arView: MTKView = {
        let view = MTKView()
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.framebufferOnly = false
        view.autoResizeDrawable = true
        view.contentMode = .scaleAspectFill
        view.preferredFramesPerSecond = 30
        view.isOpaque = true
        return view
    }()
}
