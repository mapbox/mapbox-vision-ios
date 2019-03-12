//
//  VisionPresentationViewController.swift
//  cv-assist-ios
//
//  Created by Maksim on 12/14/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MetalKit
import AVKit
import MapboxVisionCore

protocol VideoStreamPresentable: VisionPresentationControllable {
    func present(sampleBuffer: CMSampleBuffer)
    func present(visualizationMode: VisualizationMode)
    
    func present(debugOverlay: UIImage?)
    func present(fps: FPSValue?)
    
    func present(segMask: SegmentationMask?)
    func present(detections: Detections?, canvasSize: CGSize)
    
    func showClearCacheAlert()
    
    func presentRecordingPicker(dataSource: RecordDataSource)
    func presentVideo(at url: URL)
}

private let contentInset: CGFloat = 16
private let safeAreaContentInset: CGFloat = 2
private let additionalContentInset: CGFloat = 7
private let baseLineContentInset: CGFloat = 18

private let bigRelativeInset: CGFloat = 23
private let smallRelativeInset: CGFloat = 16
private let innerRelativeInset: CGFloat = 10

private let buttonHeight: CGFloat = 36

private let maneuverSignWidth: CGFloat = 78
private let maneuverSignHeight: CGFloat = 105

private let roadLanesTopInset: CGFloat = 18
private let roadLanesHeight: CGFloat = 64

private let signImageAlignInsets = UIEdgeInsets(top: 6, left: 7, bottom: 8, right: 7)

final class VisionViewController: VisionPresentationViewController {
    public var frameVisualizationMode: VisualizationMode = .clear {
        didSet {
            let oldTopView = view(for: oldValue)
            oldTopView.isHidden = true
            
            let newTopView = view(for: frameVisualizationMode)
            newTopView.isHidden = false
            backgroundView.bringSubview(toFront: newTopView)
        }
    }
    
    public var isLogoVisible: Bool {
        get {
            return !logoView.isHidden
        }
        set {
            logoView.isHidden = !newValue
        }
    }
    
    weak var interactor: VideoStreamInteractable?
    private let dateFormatter = DateFormatter()
    
    private let alertPlayer = AlertPlayer()
    
    private var contentContainerConstraints = [NSLayoutConstraint]()
    
    private let syncDebouncer = Debouncer(delay: 0.5)
    
    private var externalWindow: UIWindow?
    
    private var notificationObservers = [Any]()
    
    private func view(for mode: VisualizationMode) -> UIView {
        switch mode {
        case .clear:
            return videoStreamView
        case .segmentation:
            return segmentationView
        case .detection:
            return detectionsView
        }
    }
  
    private lazy var segmentationDrawer: SegmentationDrawer? = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            assertionFailure("SegmentationDrawer: Can't create MTLDevice")
            return nil
        }
        return SegmentationDrawer(device: device)
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        
        dateFormatter.timeStyle = .short
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        setupContentView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let center = NotificationCenter.default
        notificationObservers.append(center.addObserver(forName: .UIScreenDidConnect, object: nil, queue: .main) { [weak self] notification in
            guard let screen = notification.object as? UIScreen else { return }
            self?.externalWindow = UIWindow(frame: screen.bounds)
            self?.externalWindow?.screen = screen
        })
    
        notificationObservers.append(center.addObserver(forName: .UIScreenDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            self?.externalWindow = nil
        })
        
        setupContentView()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        notificationObservers.removeAll()
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.setupContentView()
        })
    }
    
    private func setupLayout() {
        setupBackgroundView()
        
        view.addSubview(debugView)
    }
    
    private func setupBackgroundView() {
        view.addSubview(backgroundView)
    }
    
    private func setupContentLayout() {
        view.addSubview(contentView)
        setupFPSLabels()
    }
    
    private func setupFPSLabels() {
        segmentationFPSLabel = fpsLabel()
        detectionFPSLabel = fpsLabel()
        mergedSegDetectFPSLabel = fpsLabel()
        roadConfidenceFPSLabel = fpsLabel()
        coreUpdateFPSLabel = fpsLabel()
        let stack = UIStackView(arrangedSubviews: [
            fpsStack(views: [fpsLabel(text: "Segmentation:"), segmentationFPSLabel]),
            fpsStack(views: [fpsLabel(text: "Detection:"), detectionFPSLabel]),
            fpsStack(views: [fpsLabel(text: "Merged S+D:"), mergedSegDetectFPSLabel]),
            fpsStack(views: [fpsLabel(text: "Road conf:"), roadConfidenceFPSLabel]),
            fpsStack(views: [fpsLabel(text: "Core update:"), coreUpdateFPSLabel]),
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .equalCentering
        stack.spacing = innerRelativeInset
        stack.isHidden = true
        measurementStack = stack
        
        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        stack.insertSubview(backgroundView, at: 0)
        
        view.addSubview(stack)
    }
    
    private func fpsLabel(text: String? = nil) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont(name: "Menlo", size: 10)
        label.text = text
        return label
    }
    
    private func fpsStack(views: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = innerRelativeInset
        stack.distribution = .equalCentering
        return stack
    }

    private let videoStreamView: VideoStreamView = {
        let view = VideoStreamView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let debugView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let segmentationView: MTKView = {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = false
        view.autoResizeDrawable = false
        view.contentMode = .scaleAspectFill
        view.isHidden = true
        view.isPaused = true
        view.enableSetNeedsDisplay = false
        return view
    }()
    
    private let detectionsView: DetectionsView = {
        let view = DetectionsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()
    
    private let logoView: UIView = {
        let view = UIImageView(image: VisionImages.logo.image)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0.5
        return view
    }()
    
    private var segmentationFPSLabel: UILabel!
    private var detectionFPSLabel: UILabel!
    private var mergedSegDetectFPSLabel: UILabel!
    private var roadConfidenceFPSLabel: UILabel!
    private var coreUpdateFPSLabel: UILabel!
    private var measurementStack: UIStackView!
}

extension VisionViewController: VideoStreamPresentable {
    func present(sampleBuffer: CMSampleBuffer) {
        DispatchQueue.main.async {
            self.videoStreamView.enqueue(sampleBuffer)
        }
    }
    
    func present(visualizationMode: VisualizationMode) {
        self.frameVisualizationMode = visualizationMode
    }

    func present(fps: FPSValue?) {
        measurementStack.isHidden = fps == nil
        guard let fps = fps else { return }
        segmentationFPSLabel.text = String(format: "%.2f", fps.segmentation)
        detectionFPSLabel.text = String(format: "%.2f", fps.detection)
        mergedSegDetectFPSLabel.text = String(format: "%.2f", fps.mergedSegmentationDetection)
        roadConfidenceFPSLabel.text = String(format: "%.2f", fps.roadConfidence)
        coreUpdateFPSLabel.text = String(format: "%.2f", fps.coreUpdate)
    }

    func present(debugOverlay: UIImage?) {
        debugView.image = debugOverlay
    }
    
    func present(segMask: SegmentationMask?) {
        guard let segMask = segMask else {
            segmentationView.isHidden = true
            return
        }

        if segmentationView.delegate == nil {
            segmentationView.delegate = segmentationDrawer
        }
        
        segmentationView.isHidden = false
        segmentationView.drawableSize = CGSize(width: CGFloat(segMask.sourceImage.width), height: CGFloat(segMask.sourceImage.height))
        segmentationDrawer?.set(segMask)
        segmentationView.draw()
    }
    
    func present(detections: Detections?, canvasSize: CGSize) {
        
        guard
            let detections = detections,
            let image = detections.sourceImage.getUIImage()
        else {
            detectionsView.isHidden = true
            return
        }
        
        let values = detections.items.map { detection -> Detection in
            
            let leftTop = detection.boundingBox.origin.convertForAspectRatioFill(
                from: canvasSize,
                to: detectionsView.bounds.size
            )
            
            let rightBottom = CGPoint(x: detection.boundingBox.maxX,
                                      y: detection.boundingBox.maxY)
                .convertForAspectRatioFill(from: canvasSize, to: detectionsView.bounds.size)
            
            let rect = CGRect(
                x: leftTop.x,
                y: leftTop.y,
                width: rightBottom.x - leftTop.x,
                height: rightBottom.y - leftTop.y
            )
            
            return Detection(identifier: detection.identifier,
                             boundingBox: rect,
                             objectType: detection.objectType,
                             confidence: detection.confidence)
        }
        
        detectionsView.isHidden = false
        detectionsView.present(detections: values, at: image)
    }
    
    func showClearCacheAlert() {
        let alert = UIAlertController(title: "Clearing the cache", message: "Do you want to clear the cache?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "YES", style: .destructive, handler: { [weak self] _ in
            self?.interactor?.clearCache(force: true)
        }))
        alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
        show(alert, sender: self)
    }
    
    func presentRecordingPicker(dataSource: RecordDataSource) {
        let picker = RecordPickerViewController(dataSource: dataSource) { [weak self] url in
            if let url = url {
                self?.interactor?.selectRecording(at: url)
            }
            self?.dismiss(animated: true)
        }
        let navigationController = UINavigationController(rootViewController: picker)
        present(navigationController, animated: true)
    }
    
    func presentVideo(at url: URL) {
        let player = AVPlayer(url: url)
        
        let playerController = AVPlayerViewController()
        playerController.player = player
        playerController.showsPlaybackControls = false
        playerController.entersFullScreenWhenPlaybackBegins = true
        
        externalWindow?.rootViewController = playerController
        externalWindow?.isHidden = false
        
        player.play()
    }
}
