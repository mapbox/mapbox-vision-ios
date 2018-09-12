//
//  MetaInfoManager.swift
//  cv-assist-ios
//
//  Created by Maksim on 1/15/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import CoreLocation

protocol MetaInfoObserver: class {
    func location(_ location: CLLocation)
    func heading(_ heading: CLHeading)
}

final class MetaInfoManager: NSObject, CLLocationManagerDelegate {
    
    private struct MetaInfoObserverBox: Hashable {
        let hashValue: Int
        let observer: MetaInfoObserver
        
        init(_ observer: MetaInfoObserver) {
            self.observer = observer
            hashValue = ObjectIdentifier(observer).hashValue
        }
        
        static func == (lhs: MetaInfoManager.MetaInfoObserverBox, rhs: MetaInfoManager.MetaInfoObserverBox) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
    }
    
    private let locationManager = CLLocationManager()
    private var isReady = false
    private var isStarted = false
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            isReady = false
        case .authorizedAlways, .authorizedWhenInUse:
            isReady = true
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateOrientation), name: Notification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined, .restricted, .denied:
            isReady = false
        case .authorizedWhenInUse, .authorizedAlways:
            let oldReady = isReady
            isReady = true
            if isStarted, !oldReady {
                start()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach { location in
            observers.forEach { box in
                box.observer.location(location)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        observers.forEach { box in
            box.observer.heading(newHeading)
        }
    }
    
    func start() {
        isStarted = true
        guard isReady else { return }
        self.locationManager.startUpdatingLocation()
        self.locationManager.startUpdatingHeading()
    }
    
    func stop() {
        isStarted = false
        self.locationManager.stopUpdatingLocation()
        self.locationManager.stopUpdatingHeading()
    }
    
    private var observers: Set<MetaInfoObserverBox> = []
    
    func addObserver(_ observer: MetaInfoObserver) {
        observers.insert(MetaInfoObserverBox(observer))
    }
    
    func removeObserver(_ observer: MetaInfoObserver) {
        observers.remove(MetaInfoObserverBox(observer))
    }
    
    @objc private func updateOrientation() {
        locationManager.headingOrientation = UIDevice.current.orientation.clDeviceOrientation
    }
}

fileprivate extension UIDeviceOrientation {
    var clDeviceOrientation: CLDeviceOrientation {
        switch self {
        case .unknown:            return .unknown
        case .portrait:           return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft:      return .landscapeLeft
        case .landscapeRight:     return .landscapeRight
        case .faceUp:             return .faceUp
        case .faceDown:           return .faceDown
        }
    }
}
