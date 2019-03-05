//
//  CoreUpdater.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 2/23/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionCore

private let milliSecToMicroSec: Float = 1_000
private let secToMicroSec: Float = 1_000_000
private let frameDuration = 30 * milliSecToMicroSec

final class CoreUpdater {
    typealias UpdateHandler = () -> Void
    
    private let core: Core
    private var updateHandler: UpdateHandler?
    private var updateHandlerQueue: DispatchQueue?

    private var displayLink: CADisplayLink?
    
    private let updateQueue = DispatchQueue(label: "com.mapbox.core.update", qos: DispatchQoS.default)
    
    private var isRunningSemaphore = DispatchSemaphore(value: 1)
    private var _isRunning = false
    var isRunning: Bool {
        get {
            isRunningSemaphore.wait()
            let temp = _isRunning
            isRunningSemaphore.signal()
            return temp
        }
        set {
            isRunningSemaphore.wait()
            _isRunning = newValue
            isRunningSemaphore.signal()
        }
    }
    
    init(core: Core) {
        self.core = core
    }
    
    func set(updateHandlerQueue: DispatchQueue, updateHandler: @escaping UpdateHandler) {
        self.updateHandlerQueue = updateHandlerQueue
        self.updateHandler = updateHandler
    }
    
    func startUpdating() {
        self.core.resume()
        
        guard !isRunning else { return }
        
        isRunning = true

        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(self.updateOnDisplayLink))
            displayLink!.add(to: .main, forMode: .defaultRunLoopMode)
        } else {
            displayLink?.isPaused = false
        }

//        updateQueue.async { [weak self] in
//            self?.startLoop()
//        }
    }
    
    func stopUpdating() {
        isRunning = false
        displayLink?.isPaused = true
        self.core.pause()
    }
    
    private func startLoop() {
        while isRunning {
            let updateDuration = core.update() * secToMicroSec
            
            if let queue = updateHandlerQueue, let handler = updateHandler {
                queue.async(execute: handler)
            }
            
            if (frameDuration > updateDuration) {
                let delayTime = UInt32(frameDuration - updateDuration)
                usleep(delayTime)
            }
        }
    }

    @objc private func updateOnDisplayLink(_ sender: CADisplayLink) {

//        var currentTime = kCMTimeInvalid
//        let nextVSync = sender.timestamp + sender.duration

        if let queue = updateHandlerQueue, let handler = updateHandler {
            queue.async(execute: handler)
        }
    }
}
