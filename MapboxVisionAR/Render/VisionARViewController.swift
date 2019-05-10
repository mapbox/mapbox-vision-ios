//
// Created by Alexander Pristavko on 8/21/18.
// Copyright (c) 2018 Mapbox. All rights reserved.
//

import Foundation
import UIKit
import MetalKit
import MapboxVision
import MapboxCoreNavigation
import MapboxVisionARNative
import CoreMedia

/**
    Class that represents visual component that renders video stream from the camera and AR navigation route on top of that.
*/
public class VisionARViewController: UIViewController {
    
    /**
        The delegate object to receive navigation events.
    */
    public weak var navigationDelegate: NavigationManagerDelegate?
    
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
    private var navigationManager: NavigationManager?
    
    /**
        Create an instance of VisionARNavigationController by specifying route controller from MapboxCoreNavigation framework.
    */
    public init(navigationService: NavigationService? = nil) {
        
        super.init(nibName: nil, bundle: nil)
        
        self.navigationService = navigationService
        setNavigationService(navigationService)
        
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
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
        NavigationService from MapboxCoreNavigation framework
    */
    public var navigationService: NavigationService? {
        didSet {
            setNavigationService(navigationService)
        }
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
    
    private func setNavigationService(_ navigationService: NavigationService?) {
        if let navigationService = navigationService {
            navigationManager = NavigationManager(navigationService: navigationService)
            navigationManager?.delegate = navigationDelegate
        } else {
            navigationManager = nil
        }
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
