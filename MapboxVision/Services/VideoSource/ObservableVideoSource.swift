//
//  ObservableVideoSource.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 3/27/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation

open class ObservableVideoSource: NSObject, VideoSource {
    
    open var isExternal = true
    
    open func add(observer: VideoSourceObserver) {
        let id = ObjectIdentifier(observer)
        observations[id] = Observation(observer: observer)
    }
    
    open func remove(observer: VideoSourceObserver) {
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }
    
    public func notify(_ closure: (VideoSourceObserver) -> Void) {
        observations.forEach { (id, observation) in
            guard let observer = observation.observer else {
                observations.removeValue(forKey: id)
                return
            }
            closure(observer)
        }
    }
    
    private struct Observation {
        weak var observer: VideoSourceObserver?
    }
    
    private var observations = [ObjectIdentifier : Observation]()
}
