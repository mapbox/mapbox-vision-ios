//
//  ExternalCameraViewController.swift
//  ExternalCameraSample
//
//  Copyright © 2019 Mapbox. All rights reserved.
//

import UIKit
import MapboxVision

class FileVideoSource: ObservableVideoSource {
    
    private let reader: AVAssetReader
    private let queue = DispatchQueue(label: "FileVideoSourceQueue")
    private lazy var timer: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.preferredFramesPerSecond = 30
        return displayLink
    }()
    
    init(url: URL) {
        let asset = AVAsset(url: url)
        reader = try! AVAssetReader(asset: asset)
        
        super.init()
        
        let videoTrack = asset.tracks(withMediaType: .video).first!
        let output = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)]
        )
        reader.add(output)
    }
    
    func start() {
        queue.async { [unowned self] in
            self.reader.startReading()
            self.timer.add(to: .main, forMode: .default)
        }
    }
    
    @objc func update() {
        queue.async { [unowned self] in
            if let buffer = self.reader.outputs.first?.copyNextSampleBuffer() {
                self.notify { observer in
                    let videoSample = VideoSample(buffer: buffer, format: .BGRA)
                    observer.videoSource(self, didOutput: videoSample)
                }
            } else {
                self.timer.invalidate()
                self.reader.cancelReading()
            }
        }
    }
}


class ExternalCameraViewController: UIViewController, VisionManagerDelegate {
    private var fileVideoSource: FileVideoSource!
    private var visionManager: VisionManager!
    private let visionViewController = VisionPresentationViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addVisionView()
        
        fileVideoSource = FileVideoSource(url: Bundle.main.url(forResource: "video", withExtension: "mp4")!)
        visionManager = VisionManager.create(videoSource: fileVideoSource)
        
        fileVideoSource.add(observer: self)
        visionManager.start(delegate: self)
        
        fileVideoSource.start()
    }
    
    func addVisionView() {
        addChild(visionViewController)
        view.addSubview(visionViewController.view)
        NSLayoutConstraint.activate([
            visionViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            visionViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            visionViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            visionViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
        visionViewController.didMove(toParent: self)
    }
}

extension ExternalCameraViewController: VideoSourceObserver {
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {
        DispatchQueue.main.async { [unowned self] in
            self.visionViewController.present(sampleBuffer: videoSample.buffer)
        }
    }
}
