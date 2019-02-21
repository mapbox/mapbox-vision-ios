//
//  Streamable.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 9/24/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

public protocol Streamable {
    func start()
    func stop()
}

final class AlwaysRunningStream: Streamable {
    private let stream: Streamable
    
    init(stream: Streamable) {
        self.stream = stream
        stream.start()
    }
    
    func start() {}
    
    func stop() {}
}

final class ControlledStream: Streamable {
    private let stream: Streamable
    
    init(stream: Streamable) {
        self.stream = stream
    }
    
    func start() {
        stream.start()
    }
    
    func stop() {
        stream.stop()
    }
}
