//
//  ViewController.swift
//  ExternalCameraSample
//
//  Copyright © 2019 Mapbox. All rights reserved.
//

import UIKit
import MapboxVision

class ViewController: UIViewController, VisionManagerDelegate {
    
    private var fileVideoSource: FileVideoSource!
    private var visionMananger: VisionManager!
    private let visionViewController = VisionPresentationViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(visionViewController)
        view.addSubview(visionViewController.view)
        
        fileVideoSource = FileVideoSource(url: Bundle.main.url(forResource: "video", withExtension: "mp4")!)
        visionMananger = VisionManager.create(videoSource: fileVideoSource)
        
        fileVideoSource.add(observer: self)
        visionMananger.start(delegate: self)
        fileVideoSource.start()
    }
}

extension ViewController: VideoSourceObserver {
    
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {
        DispatchQueue.main.async { [unowned self] in
            self.visionViewController.present(sampleBuffer: videoSample.buffer)
        }
    }
}
