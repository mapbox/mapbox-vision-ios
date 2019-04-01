//
//  ViewController.swift
//  VisionARSample
//
//  Copyright © 2019 Mapbox. All rights reserved.
//

import UIKit
import MapboxVision
import MapboxVisionAR
import MapboxDirections
import MapboxCoreNavigation

class ARNavigationViewController: UIViewController {
    private var videoSource: CameraVideoSource!
    private var visionManager: VisionManager!
    private var visionARManager: VisionARManager!

    private let visionARViewController = VisionARViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addARView()
        
        videoSource = CameraVideoSource()
        videoSource.add(observer: self)
        
        visionManager = VisionManager.create(videoSource: videoSource)
        visionARManager = VisionARManager.create(visionManager: visionManager, delegate: self)
        
        let origin = CLLocationCoordinate2D()
        let destination = CLLocationCoordinate2D()
        let options = NavigationRouteOptions(coordinates: [origin, destination], profileIdentifier: .automobile)
        
        Directions.shared.calculate(options) { [weak self] (waypoints, routes, error) in
            guard let route = routes?.first else { return }
            self?.visionARManager.set(route: Route(route: route))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        visionManager.start()
        videoSource.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        videoSource.stop()
        visionManager.stop()
        visionARManager.destroy()
    }
    
    private func addARView() {
        addChild(visionARViewController)
        view.addSubview(visionARViewController.view)
        visionARViewController.didMove(toParent: self)
    }
}

extension ARNavigationViewController: VisionARDelegate {
    func visionARManager(visionARManager: VisionARManager, didUpdateARLane lane: ARLane?) {
        DispatchQueue.main.async { [weak self] in
            self?.visionARViewController.present(lane: lane)
        }
    }
    
    func visionARManager(visionARManager: VisionARManager, didUpdateARCamera camera: ARCamera) {
        DispatchQueue.main.async { [weak self] in
            self?.visionARViewController.present(camera: camera)
        }
    }
}

extension ARNavigationViewController: VideoSourceObserver {
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {
        DispatchQueue.main.async { [weak self] in
            self?.visionARViewController.present(sampleBuffer: videoSample.buffer)
        }
    }
}
